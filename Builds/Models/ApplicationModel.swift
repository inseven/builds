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
            WidgetCenter.shared.reloadTimelines(ofKind: "BuildsWidget")
        }
    }
    @MainActor @Published var results: [WorkflowInstance] = []

    // Indicates that the user has signed in, not that they have a valid authentication. This allows us to differentiate
    // recoverable authentication failures from the initial set up.
    @MainActor @Published var isSignedIn: Bool

    @MainActor @Published var favorites: [WorkflowInstance.ID] = [] {
        didSet {
            settings.favorites = favorites
        }
    }

    @MainActor @Published var cachedStatus: [WorkflowInstance.ID: WorkflowResult] = [:] {
        didSet {
            settings.cachedStatus = cachedStatus
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

    // TODO: Make this private.
    // This implementation is intentionally side effecty; if it notices that there's no longer an access token, it will
    // set isSignedIn to false. This is to avoid explicitly polling for authentication changes when we already have a
    // mechanism which has to poll the GitHub API fairly frequently for updates and means we're not hitting the keychain
    // more than we need to.
    @MainActor var client: GitHubClient {
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

    override init() {
        let configuration = Bundle.main.configuration()
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
                try await self.client.update(favorites: self.favorites) { [weak self] workflowInstance in
                    guard let self else {
                        return
                    }
                    // Don't update the cache unless the contents have changed as this will cause an unnecessary redraw.
                    guard self.cachedStatus[workflowInstance.id] != workflowInstance.result else {
                        return
                    }
                    self.cachedStatus[workflowInstance.id] = workflowInstance.result
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
        self.organizations = favorites
            .reduce(into: Set<String>()) { partialResult, id in
                partialResult.insert(id.organization)
            }.sorted()
    }

    @MainActor private func updateResults() {
        self.results = favorites
            .map { id in
                return WorkflowInstance(id: id, result: cachedStatus[id])
            }
            .sorted {
                $0.repositoryName.localizedStandardCompare($1.repositoryName) == .orderedAscending
            }
    }

    @MainActor private func start() {

        // Start the refresh scheduler.
        refreshScheduler.start()

        // Update the state whenever a user changes the favorites.
        $favorites
            .combineLatest($isSignedIn)
            .compactMap { (favorites, isAuthorized) -> [WorkflowInstance.ID]? in
                guard isAuthorized else {
                    return nil
                }
                return favorites
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)

        // Generate the results.
        $favorites
            .combineLatest($cachedStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateResults()
            }
            .store(in: &cancellables)

        // Generate the organizations.
        $favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOrganizations()
            }
            .store(in: &cancellables)

        // Generate an over-arching build summary used to back insight windows and widgets.
        $results
            .map { (results) -> Summary? in
                guard results.count > 0 else {
                    return nil
                }
                var status: OperationState.Summary = .success
                for result in results {
                    switch result.summary {
                    case .unknown:
                        status = .unknown
                        break
                    case .success:  // We require 100% successes for success.
                        continue
                    case .skipped:  // Skipped builds don't represent failure.
                        continue
                    case .failure:  // We treat any failure as a global failure.
                        status = .failure
                        break
                    case .inProgress:
                        status = .inProgress
                        break
                    }
                }
                let date = results.compactMap({ $0.createdAt }).max()
                return Summary(status: status, count: results.count, date: date)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.summary, on: self)
            .store(in: &cancellables)

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

        // Load the cached contents to ensure the UI doesn't flash on initial load.
        sync()
        updateOrganizations()
        updateResults()
    }

    @MainActor func addFavorite(_ id: WorkflowInstance.ID) {
        guard !favorites.contains(id) else {
            return
        }
        favorites.append(id)

        // Fetch the workflow details on demand.
        Task {
            await refresh(ids: [id])
        }
    }

    @MainActor func removeFavorite(_ id: WorkflowInstance.ID) {
        favorites.removeAll { $0 == id }
        cachedStatus.removeValue(forKey: id)
    }

    @MainActor func logIn() {
        Application.open(api.authorizationURL)
    }

    @MainActor func sync() {
        let favorites = settings.favorites
        guard self.favorites != favorites else {
            return
        }
        self.favorites = favorites
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

    @MainActor func signOut(preserveFavorites: Bool) async {
        do {
            if let accessToken = settings.accessToken {
                try await api.deleteGrant(accessToken: accessToken)
            }
        } catch {
            print("Failed to delete client grant with error \(error).")
        }
        settings.accessToken = nil
        cachedStatus = [:]
        if !preserveFavorites {
            favorites = []
        }
        isSignedIn = false
    }

    @MainActor func managePermissions() {
        Application.open(api.permissionsURL)
    }

    func refresh() async {
        await refreshScheduler.run()
    }

    func refresh(ids: [WorkflowInstance.ID]) async {
        do {
            try await client.update(favorites: ids) { [weak self] workflowInstance in
                guard let self else {
                    return
                }
                // Don't update the cache unless the contents have changed as this will cause an unnecessary redraw.
                guard self.cachedStatus[workflowInstance.id] != workflowInstance.result else {
                    return
                }
                self.cachedStatus[workflowInstance.id] = workflowInstance.result
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

}
