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

import Interact

@MainActor
class ApplicationModel: NSObject, ObservableObject, AuthenticationProvider {

    private enum Key: String {
        case items
        case status
        case lastUpdate
        case accessToken
        case favorites
    }

    @MainActor @Published var actions: [Action] = [] {
        didSet {
            do {
                let data = try JSONEncoder().encode(actions)
                let store = NSUbiquitousKeyValueStore.default
                guard store.data(forKey: Key.favorites.rawValue) != data else {
                    return
                }
                store.set(data, forKey: Key.favorites.rawValue)
                store.synchronize()
            } catch {
                print("Failed to save actions with error \(error).")
            }
        }
    }

    @MainActor func addAction(_ action: Action) {
        guard !actions.contains(action) else {
            return
        }
        actions.append(action)
    }

    @MainActor func removeAction(_ action: Action) {
        actions.removeAll { $0.id == action.id }
    }

    @MainActor @Published var isUpdating: Bool = false
    @MainActor @Published var summary: SummaryState = .unknown
    @MainActor @Published var results: [WorkflowResult] = []

    @MainActor @Published var authenticationToken: GitHub.Authentication? {
        didSet {
            do {
                try keychain.set(authenticationToken?.accessToken, forKey: .accessToken)
            } catch {
                print("Failed to update keychain with error \(error).")
            }
        }
    }

    @MainActor var isAuthorized: Bool {
        return authenticationToken != nil
    }

    @MainActor @Published var cachedStatus: [Action.ID: WorkflowSummary] = [:] {
        didSet {
            do {
                try defaults.set(codable: cachedStatus, forKey: .status)
            } catch {
                print("Failed to save status with error \(error).")
            }
        }
    }

    @MainActor @Published var lastUpdate: Date? {
        didSet {
            defaults.set(lastUpdate, forKey: .lastUpdate)
        }
    }

    @MainActor @Published private var activeScenes = 0 {
        didSet {
            print("activeScenes = \(activeScenes)")
        }
    }

    // TODO: Make this private.
    @MainActor let client: GitHubClient

    @MainActor private let defaults = KeyedDefaults<Key>()
    @MainActor private let keychain = KeychainManager<Key>()
    @MainActor private var cancellables = Set<AnyCancellable>()
    @MainActor private var refreshScheduler: RefreshScheduler!

    override init() {
        let configuration = Bundle.main.configuration()
        let api = GitHub(clientId: configuration.clientId,
                         clientSecret: configuration.clientSecret,
                         redirectUri: "x-builds-auth://oauth")
        self.client = GitHubClient(api: api)
        self.cachedStatus = (try? defaults.codable(forKey: .status, default: [Action.ID: WorkflowSummary]())) ?? [:]
        self.lastUpdate = defaults.object(forKey: .lastUpdate) as? Date
        if let accessToken = try? keychain.string(forKey: .accessToken) {
            self.authenticationToken = GitHub.Authentication(accessToken: accessToken)
        } else {
            self.authenticationToken = nil
        }

        super.init()

        self.client.authenticationProvider = self

        refreshScheduler = RefreshScheduler { [weak self] in
            guard let self else {
                return nil
            }
            do {
                print("Refreshing...")
                self.isUpdating = true
                let results = try await self.actions.map { action in
                    return try await self.update(action: action)
                }
                let cachedStatus = results.reduce(into: [Action.ID: WorkflowSummary]()) { partialResult, workflowResult in
                    partialResult[workflowResult.action.id] = workflowResult.summary
                }

                self.cachedStatus = cachedStatus
                self.lastUpdate = Date()
            } catch {
                print("Failed to update with error \(error).")
            }
            self.isUpdating = false
            print("Done")
            return self.activeScenes > 0 ? .minutes(1.0) : .minutes(5.0)
        }

        self.start()
    }

    @MainActor private func start() {

        // Start the refresh scheduler.
        refreshScheduler.start()

        // Update the state whenever a user changes the favorites.
        $actions
            .combineLatest($authenticationToken)
            .compactMap { (actions, token) -> [Action]? in
                guard token != nil else {
                    return nil
                }
                return actions
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)

        // Generate the results array used to back the main window.
        $actions
            .combineLatest($cachedStatus)
            .map { actions, cachedStatus in
                return actions.map { action in
                    return WorkflowResult(action: action, summary: cachedStatus[action.id])
                }
                .sorted {
                    $0.action.repositoryName.localizedStandardCompare($1.action.repositoryName) == .orderedAscending
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.results, on: self)
            .store(in: &cancellables)

        // Generate an over-arching build summary used to back insight windows and widgets.
        $results
            .map { (results) -> SummaryState in
                guard results.count > 0 else {
                    return .unknown
                }
                for result in results {
                    switch result.state {
                    case .unknown:
                        return .unknown
                    case .success:  // We require 100% successes for success.
                        continue
                    case .failure:  // We treat any failure as a global failure.
                        return .failure
                    case .inProgress:
                        return .inProgress
                    }
                }
                return .success
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.summary, on: self)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .prepend(.init(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.sync()
                }
            }
            .store(in: &cancellables)

    }

    @MainActor func logIn() {
        Application.open(client.authorizationURL)
    }

    @MainActor func sync() {
        do {
            NSUbiquitousKeyValueStore.default.synchronize()
            guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Key.favorites.rawValue) else {
                return
            }
            let actions = try JSONDecoder().decode([Action].self, from: data)
            guard self.actions != actions else {
                return
            }
            self.actions = actions
        } catch {
            print("Failed to update actions with error \(error).")
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
        try await client.authenticate(with: code)
    }

    @MainActor func logOut() {
        authenticationToken = nil
        cachedStatus = [:]
    }

    @MainActor func managePermissions() {
        Application.open(client.permissionsURL)
    }

    func update(action: Action) async throws -> WorkflowResult {
        let workflowRuns = try await client.workflowRuns(for: action.repositoryFullName)

        let latestRun = workflowRuns.first { workflowRun in
            if workflowRun.workflowId != action.workflowId {
                return false
            }
            if workflowRun.headBranch != action.branch {
                return false
            }
            return true
        }

        guard let latestRun else {
            return WorkflowResult(action: action, summary: nil)
        }

        let workflowJobs = try await client.workflowJobs(for: action.repositoryFullName, workflowRun: latestRun)
        var annotations: [GitHub.Annotation] = []
        for workflowJob in workflowJobs {
            annotations.append(contentsOf: try await client.annotations(for: action.repositoryFullName,
                                                                        workflowJob: workflowJob))
        }

        return WorkflowResult(action: action,
                              summary: WorkflowSummary(workflowRun: latestRun, annotations: annotations))
    }

    func refresh() async {
        await refreshScheduler.run()
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

}
