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
class ApplicationModel: NSObject, ObservableObject {

    private enum Key: String {
        case items
        case status
        case lastUpdate
        case accessToken
        case favorites
        case useInAppBrowser
        case sceneSettings
    }

    @MainActor @Published var favorites: [WorkflowInstance.ID] = [] {
        didSet {
            do {
                let data = try JSONEncoder().encode(favorites)
                let store = NSUbiquitousKeyValueStore.default
                guard store.data(forKey: Key.favorites.rawValue) != data else {
                    return
                }
                store.set(data, forKey: Key.favorites.rawValue)
                store.synchronize()
            } catch {
                print("Failed to save favorites with error \(error).")
            }
        }
    }

    @MainActor @Published var organizations: [String] = []
    @MainActor @Published var isUpdating: Bool = false
    @MainActor @Published var summary: SummaryState = .unknown
    @MainActor @Published var results: [WorkflowInstance] = []

    // Indicates that the user has signed in, not that they have a valid authentication. This allows us to differentiate
    // recoverable authentication failures from the initial set up.
    @MainActor @Published var isSignedIn: Bool

    @MainActor @Published var cachedStatus: [WorkflowInstance.ID: WorkflowResult] = [:] {
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

    @MainActor @Published var useInAppBrowser: Bool {
        didSet {
            defaults.set(useInAppBrowser, forKey: .useInAppBrowser)
        }
    }

    @MainActor @Published var defaultSceneSettings: SceneModel.Settings {
        didSet {
            try? defaults.set(codable: defaultSceneSettings, forKey: .sceneSettings)
        }
    }

    @MainActor @Published var lastError: Error? = nil

    @MainActor @Published private var activeScenes = 0

    @MainActor private var accessToken: String? {
        get {
            return try? keychain.string(forKey: .accessToken)
        }
        set {
            try? keychain.set(newValue, forKey: .accessToken)
        }
    }

    // TODO: Make this private.
    // This implementation is intentionally side effecty; if it notices that there's no longer an access token, it will
    // set isSignedIn to false. This is to avoid explicitly polling for authentication changes when we already have a
    // mechanism which has to poll the GitHub API fairly frequently for updates and means we're not hitting the keychain
    // more than we need to.
    @MainActor var client: GitHubClient {
        get throws {
            do {
                guard let accessToken else {
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

    @MainActor private let defaults = KeyedDefaults<Key>()
    @MainActor private let keychain = KeychainManager<Key>()
    @MainActor private var cancellables = Set<AnyCancellable>()
    @MainActor private var refreshScheduler: RefreshScheduler!

    private let api: GitHub

    var authorizationURL: URL {
        return api.authorizationURL
    }

    var permissionsURL: URL {
        return api.permissionsURL
    }

    override init() {
        let configuration = Bundle.main.configuration()
        self.api = GitHub(clientId: configuration.clientId,
                          clientSecret: configuration.clientSecret,
                          redirectUri: "x-builds-auth://oauth")
        self.cachedStatus = (try? defaults.codable(forKey: .status)) ?? [:]
        self.lastUpdate = defaults.object(forKey: .lastUpdate) as? Date
        self.useInAppBrowser = defaults.bool(forKey: .useInAppBrowser, default: true)
        self.defaultSceneSettings = (try? defaults.codable(forKey: .sceneSettings)) ?? SceneModel.Settings()
        self.isSignedIn = (try? keychain.string(forKey: .accessToken)) != nil

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
        self.organizations = favorites.reduce(into: Set<String>()) { partialResult, id in
            partialResult.insert(id.organization)
        }.sorted()
    }

    @MainActor private func updateResults() {
        self.results = favorites.map { id in
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
                    case .skipped:  // Skipped builds don't represent failure.
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
            do {
                try await client.update(favorites: [id]) { [weak self] workflowInstance in
                    guard let self else {
                        return
                    }
                    self.cachedStatus[workflowInstance.id] = workflowInstance.result
                }
            } catch {
                print("Failed fetch workflow results on demand with error \(error).")
            }
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
        do {
            NSUbiquitousKeyValueStore.default.synchronize()
            guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Key.favorites.rawValue) else {
                return
            }
            let favorites = try JSONDecoder().decode([WorkflowInstance.ID].self, from: data)
            guard self.favorites != favorites else {
                return
            }
            self.favorites = favorites
        } catch {
            print("Failed to update favorites with error \(error).")
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
        accessToken = try await api.authenticate(with: code)

        // Indicate that we're signed in.
        isSignedIn = true

        // Kick off an update.
        Task {
            await refresh()
        }
    }

    @MainActor func signOut(preserveFavorites: Bool) async {
        do {
            if let accessToken {
                try await api.deleteGrant(accessToken: accessToken)
            }
        } catch {
            print("Failed to delete client grant with error \(error).")
        }
        accessToken = nil
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

}
