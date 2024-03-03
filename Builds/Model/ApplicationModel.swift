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
    }

    @MainActor @Published var actions: [Action] = [] {
        didSet {
            do {
                try defaults.set(codable: actions, forKey: .items)
            } catch {
                print("Failed to save state with error \(error).")
            }
        }
    }

    @MainActor func addAction(_ action: Action) {
        actions.append(action)
    }

    @MainActor func removeAction(_ action: Action) {
        actions.removeAll { $0.id == action.id }
    }

    @MainActor @Published var isUpdating: Bool = false
    @MainActor @Published var summary: SummaryState = .unknown
    @MainActor @Published var status: [ActionStatus] = []

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

    @MainActor @Published var cachedStatus: [Action: ActionStatus] = [:] {
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

        self.actions = (try? defaults.codable(forKey: .items, default: [Action]())) ?? []
        self.cachedStatus = (try? defaults.codable(forKey: .status, default: [Action: ActionStatus]())) ?? [:]
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
                let elements = try await self.actions.map { action in
                    return try await self.update(action: action)
                }
                let cachedStatus = elements.reduce(into: [Action: ActionStatus]()) { partialResult, actionStatus in
                    partialResult[actionStatus.action] = actionStatus
                }

                self.cachedStatus = cachedStatus
                self.lastUpdate = Date()
            } catch {
                print("Failed to update with erorr \(error).")
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

        // Generate the status array used to back the main window.
        $actions
            .combineLatest($cachedStatus)
            .map { actions, cachedStatus in
                return actions.map { action in
                    return cachedStatus[action] ?? ActionStatus(action: action, workflowRun: nil)
                }
                .sorted {
                    $0.action.repositoryName.localizedStandardCompare($1.action.repositoryName) == .orderedAscending
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.status, on: self)
            .store(in: &cancellables)

        // Generate an over-arching build summary used to back insight windows and widgets.
        $status
            .map { (statuses) -> SummaryState in
                guard statuses.count > 0 else {
                    return .unknown
                }
                for status in statuses {
                    switch status.state {
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

    }

    @MainActor func logIn() {
        Application.open(client.authorizationURL)
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

    func update(action: Action) async throws -> ActionStatus {
        let workflowRuns = try await client.workflowRuns(for: action.repositoryFullName)

        let latestRun = workflowRuns.first { workflowRun in
            if workflowRun.workflowId != action.workflowId {
                return false
            }
            if let branch = action.branch {
                return workflowRun.headBranch == branch
            }
            return true
        }

        guard let latestRun else {
            return ActionStatus(action: action, workflowRun: latestRun)
        }

        let workflowJobs = try await client.workflowJobs(for: action.repositoryFullName, workflowRun: latestRun)
        var annotations: [GitHub.Annotation] = []
        for workflowJob in workflowJobs {
            annotations.append(contentsOf: try await client.annotations(for: action.repositoryFullName,
                                                                        workflowJob: workflowJob))
        }

        return ActionStatus(action: action, workflowRun: latestRun, annotations: annotations)
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
