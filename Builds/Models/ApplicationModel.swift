// Copyright (c) 2022-2024 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import Network
import SwiftUI
import WidgetKit

import Interact

import BuildsCore

@MainActor
class ApplicationModel: NSObject, ObservableObject {

    @MainActor @Published var organizations: [String] = []
    @MainActor @Published var isUpdating: Bool = false
    @MainActor @Published var summary: Summary? = nil {
        didSet {
            settings.summary = summary
            // TODO: #350: Widget timeline reload should be more fine-grained (https://github.com/inseven/builds/issues/350)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @MainActor @Published var results: [WorkflowInstance] = [] {
        didSet {
            updateSummary()
        }
    }

    // Indicates that the user has signed in, not that they have a valid authentication. This allows us to differentiate
    // recoverable authentication failures from the initial set up.
    @MainActor @Published var isSignedIn: Bool

    @MainActor @Published var workflows: [WorkflowInstance.ID] = [] {
        didSet {
            settings.workflows = workflows
            updateOrganizations()
            updateResults()
        }
    }

    @MainActor @Published var cachedStatus: [WorkflowInstance.ID: WorkflowInstance] = [:] {
        didSet {
            settings.cachedStatus = cachedStatus
            updateResults()
        }
    }

    @MainActor @Published var lastUpdate: Date? {
        didSet {
            settings.lastUpdate = lastUpdate
        }
    }

    @MainActor @Published var useInAppBrowser: Bool {
        didSet {
            settings.useInAppBrowser = useInAppBrowser
        }
    }

    @MainActor @Published var lastError: Error? = nil

    @MainActor @Published private var activeScenes = 0

    // This implementation is intentionally side effecty; if it notices that there's no longer an access token, it will
    // set isSignedIn to false. This is to avoid explicitly polling for authentication changes when we already have a
    // mechanism which has to poll the GitHub API fairly frequently for updates and means we're not hitting the keychain
    // more than we need to.
    @MainActor private var client: GitHubClient {
        get throws {
            do {
                guard let accessToken = settings.accessToken else {
                    throw BuildsError.authenticationFailure
                }
                if !isSignedIn {
                    isSignedIn = true
                }
                let client = GitHubClient(api: self.api, accessToken: accessToken)
                return client
            } catch {
                isSignedIn = false
                throw error
            }
        }
    }

    @MainActor let settings = Settings()

    var authorizationURL: URL {
        return api.authorizationURL
    }

    var permissionsURL: URL {
        return api.permissionsURL
    }

    @MainActor private var cancellables = Set<AnyCancellable>()
    @MainActor private var refreshScheduler: RefreshScheduler!

    private let api: GitHub
    private let networkMonitor = NWPathMonitor()

    override init() {
        let configuration = Configuration.shared
        self.api = GitHub(clientId: configuration.clientId,
                          clientSecret: configuration.clientSecret,
                          redirectUri: "x-builds-auth://oauth")
        self.cachedStatus = settings.cachedStatus
        self.lastUpdate = settings.lastUpdate
        self.useInAppBrowser = settings.useInAppBrowser
        self.isSignedIn = settings.accessToken != nil

        super.init()

        refreshScheduler = RefreshScheduler { [weak self] in
            guard let self else {
                return nil
            }
            do {
                print("Refreshing...")
                self.isUpdating = true
                self.lastError = nil
                _ = try await self.client.update(workflows: self.workflows) { [weak self] workflowInstance in
                    guard let self else {
                        return
                    }
                    // Don't update the cache unless the contents have changed as this will cause an unnecessary redraw.
                    guard self.cachedStatus[workflowInstance.id] != workflowInstance else {
                        return
                    }
                    self.cachedStatus[workflowInstance.id] = workflowInstance
                }
                self.lastUpdate = Date()
            } catch {
                self.lastError = error
                print("Failed to update with error \(error).")
            }
            self.isUpdating = false
            print("Done")
            return self.activeScenes > 0 ? .minutes(1.0) : .minutes(5.0)
        }

        self.start()
    }

    @MainActor private func updateOrganizations() {
        self.organizations = workflows
            .reduce(into: Set<String>()) { partialResult, id in
                partialResult.insert(id.organization)
            }.sorted()
    }

    @MainActor private func updateResults() {
        self.results = workflows
            .map { id in
                return cachedStatus[id] ?? WorkflowInstance(id: id)
            }
            .sorted {
                let repositoryNameOrder = $0.repositoryName.localizedStandardCompare($1.repositoryName)
                if repositoryNameOrder != .orderedSame {
                    return repositoryNameOrder == .orderedAscending
                }
                let workflowNameOrder = $0.workflowName.localizedStandardCompare($1.workflowName)
                if workflowNameOrder != .orderedSame {
                    return workflowNameOrder == .orderedAscending
                }
                return $0.id.branch.localizedStandardCompare($1.id.branch) == .orderedAscending
            }
    }

    @MainActor private func updateSummary() {
        let summary = Summary(workflowInstances: results)
        guard self.summary != summary else {
            return
        }
        self.summary = summary
    }

    @MainActor private func start() {

        // Start the refresh scheduler.
        refreshScheduler.start()

        // Watch for changes to the iCloud defaults.
        NotificationCenter.default
            .publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .prepend(.init(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.sync()
                }
            }
            .store(in: &cancellables)

        // Watch the network for availability.
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self, path.status == .satisfied else {
                return
            }
            Task {
                await self.refresh()
            }
        }
        networkMonitor.start(queue: DispatchQueue.main)

        // Load the cached contents to ensure the UI doesn't flash on initial load.
        // N.B. We don't call `updateSummary` here as this is a side effect of `updateResults` (if things have changed).
        //      It might be wise to combine these two at some point to avoid confusion.
        sync()
        updateOrganizations()
        updateResults()

        Task {
            do {
                guard let accessToken = settings.accessToken else {
                    print("Failed to get access token")
                    return
                }
                try await testStuff(accessToken: accessToken)
            } catch {
                print("Failed to perform GraphQL query with error \(error).")
            }
        }
    }

    @MainActor func addWorkflow(_ id: WorkflowInstance.ID) {
        guard !workflows.contains(id) else {
            return
        }
        workflows.append(id)
        settings.workflowsCache = workflows

        // Fetch the workflow details on demand.
        Task {
            await refresh(ids: [id])
        }
    }

    @MainActor func removeWorkflow(_ id: WorkflowInstance.ID) {
        workflows.removeAll { $0 == id }
        settings.workflowsCache = workflows
        cachedStatus.removeValue(forKey: id)
    }

    @MainActor func logIn() {
        Application.open(api.authorizationURL)
    }

    @MainActor func sync() {
        let workflows = settings.workflows

        // Cache the workflows (these are used directly by the widget configuration intent).
        settings.workflowsCache = settings.workflows

        // Guard against ping-ponging with the server and other devices.
        guard self.workflows != workflows else {
            return
        }

        // Update the workflows.
        self.workflows = workflows

        // Remove cached results that are no longer in our workflows set.
        self.cachedStatus = self.cachedStatus.filter { workflows.contains($0.key) }

        // Trigger an update if the workflows have changed in sync.
        Task {
            await refresh()
        }
    }

    func authenticate(with url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "x-builds-auth",
              components.host == "oauth",
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw BuildsError.authenticationFailure
        }

        // Get the authentication token.
        settings.accessToken = try await api.authenticate(with: code)

        // Indicate that we're signed in.
        isSignedIn = true

        // Kick off an update.
        Task {
            await refresh()
        }
    }

    @MainActor func signOut(preserveWorkflows: Bool) async {
        do {
            if let accessToken = settings.accessToken {
                try await api.deleteGrant(accessToken: accessToken)
            }
        } catch {
            print("Failed to delete client grant with error \(error).")
        }
        settings.accessToken = nil
        cachedStatus = [:]
        if !preserveWorkflows {
            workflows = []
        }
        isSignedIn = false
    }

    @MainActor func managePermissions() {
        Application.open(api.permissionsURL)
    }

    @MainActor func repositoryDetails() async throws -> [RepositoryDetails] {
        let client = try client
        let repositories = try await client
            .repositories(scope: .user)
            .asyncCompactMap { repository -> RepositoryDetails? in
                guard !repository.archived else {
                    return nil
                }
                let workflows = try await client.workflows(for: repository)
                guard workflows.count > 0 else {
                    return nil
                }
                let branches = try await client.branches(for: repository)
                return RepositoryDetails(repository: repository,
                                         workflows: workflows,
                                         branches: branches)
            }
            .sorted { $0.repository.full_name.localizedStandardCompare($1.repository.full_name) == .orderedAscending }
        return repositories
    }

    func refresh() async {
        await refreshScheduler.run()
    }

    func refresh(ids: [WorkflowInstance.ID]) async {
        do {
            _ = try await client.update(workflows: ids) { [weak self] workflowInstance in
                guard let self else {
                    return
                }
                // Don't update the cache unless the contents have changed as this will cause an unnecessary redraw.
                guard self.cachedStatus[workflowInstance.id] != workflowInstance else {
                    return
                }
                self.cachedStatus[workflowInstance.id] = workflowInstance
            }
        } catch {
            lastError = error
        }
    }

    func requestHigherFrequencyUpdates() async {
        if activeScenes < 1 {
            Task {
                await refreshScheduler.run()
            }
        }
        activeScenes = activeScenes + 1
        defer {
            activeScenes = activeScenes - 1
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60*60*24))
        }
    }

    func rerun(id: WorkflowInstance.ID, workflowRunId: Int) async throws {
        try await client.rerun(repositoryName: id.repositoryFullName, workflowRunId: workflowRunId)
        await refresh(ids: [id])
    }

    func rerunFailedJobs(id: WorkflowInstance.ID, workflowRunId: Int) async throws {
        try await client.rerunFailedJobs(repositoryName: id.repositoryFullName, workflowRunId: workflowRunId)
        await refresh(ids: [id])
    }

#if os(macOS)
    @MainActor func createSummaryPanel() {
        let summaryPanel = SummaryPanel(applicationModel: self)
        if let screen = NSScreen.main {
            let x = (screen.frame.size.width - summaryPanel.frame.size.width) / 2
            summaryPanel.setFrame(CGRectMake(x, 140, 300.0, 300.0), display: true)
        }
        summaryPanel.orderFrontRegardless()
    }
#endif

#if DEBUG

    enum FailureType {
        case authentication
    }

    @MainActor func simulateFailure(_ failureType: FailureType) async {
        switch failureType {
        case .authentication:
            settings.accessToken = "fromage"
        }
        await refresh()
    }

#endif

    func testStuff(accessToken: String) async throws {

        struct User: StaticSelectable {

            enum CodingKeys: String, CodingKey {
                case login
                case bio
            }

            @SelectionBuilder static func selections() -> [any Selectable] {
                Selection<String>(CodingKeys.login)
                Selection<String>(CodingKeys.bio)
            }

            let login: String
            let bio: String

            public init(from decoder: MyDecoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.login = try container.decode(String.self, forKey: .login)
                self.bio = try container.decode(String.self, forKey: .bio)
            }

        }

        let login = Selection<String>("login")
        let bio = Selection<String>("bio")
        let viewer = Selection<KeyedContainer>("viewer") {
            login
            bio
        }


        // TODO: It's really really important we only allow the queries to be injected.
        let userQuery = Query {
            viewer
        }

        let client = GraphQLClient(url: URL(string: "https://api.github.com/graphql")!)
        let result = try await client.query(userQuery, accessToken: accessToken)

        print(try result[viewer][login])


        let id = Selection<String>("id")
        let event = Selection<String>("event")
        let createdAt = Selection<Date>("createdAt")

        let nodes = Selection<Array<KeyedContainer>>("nodes") {
            id
            event
            createdAt
        }

        let runs = Selection<KeyedContainer>("runs", arguments: ["first" : 1]) {
            nodes
        }

        let workflow = Selection<KeyedContainer>("node", arguments: ["id": "MDg6V29ya2Zsb3c5ODk4MDM1"]) {
            Fragment("... on Workflow") {
                runs
            }
        }
        let workflowQuery = Query {
            workflow
        }

        print(workflowQuery.query())

        let workflowResult = try await client.query(workflowQuery, accessToken: accessToken)

        print(try workflowResult[workflow][runs][nodes].first![id])
        print(try workflowResult[workflow][runs][nodes].first![event])
        print(try workflowResult[workflow][runs][nodes].first![createdAt])


        // TODO: Consider that it would also be possible to copy the RegexBuilder style inline transforms...
        // We could always keep the entire extraction process internal to the decode operation and simply call our
        // custom inits with a `KeyedContainer` which would save the need for our random faked up Decoder which is
        // quite misleading. If we do it this way we don't need to rely on the coding keys at all and we can reduce
        // the risk of mismatched implementation.
    }


}


// TODO: Would need conformance.
// TODO: Rename KeyedContainer to SelectionResult?
//struct User {
//
//    static let login = Selection<String>("login")
//    static let bio = Selection<String>("bio")
//
//    @SelectionBuilder static func selections() -> [any IdentifiableSelection] {
//        login
//        bio
//    }
//
//    let login: String
//    let bio: String
//
//    public init(_ result: KeyedContainer) throws {
//        self.login = try result[Self.login]
//        self.bio = try result[Self.bio]
//    }
//
//}
