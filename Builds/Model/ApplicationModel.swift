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
class ApplicationModel: ObservableObject {

    private enum Key: String {
        case items
        case status
        case lastUpdate
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

    private let defaults: KeyedDefaults<Key>
    let client: GitHubClient

    @MainActor var cancellables = Set<AnyCancellable>()

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

    var status: [ActionStatus] {
        return actions.map { action in
            return cachedStatus[action] ?? ActionStatus(action: action, workflowRun: nil)
        }
        .sorted { $0.action.repositoryName.localizedStandardCompare($1.action.repositoryName) == .orderedAscending }
    }

    init(authentication: Binding<GitHub.Authentication?>) {

        self.defaults = KeyedDefaults()

        // TODO: Do this in start?
        actions = (try? defaults.codable(forKey: .items, default: [Action]())) ?? []
        cachedStatus = (try? defaults.codable(forKey: .status, default: [Action: ActionStatus]())) ?? [:]
        lastUpdate = defaults.object(forKey: .lastUpdate) as? Date

        let configuration = Bundle.main.configuration()
        let api = GitHub(clientId: configuration.clientId,
                         clientSecret: configuration.clientSecret,
                         redirectUri: "x-builds-auth://oauth")
        self.client = GitHubClient(api: api, authentication: authentication)
    }

    @MainActor func start() {

        // Update the state whenever a user changes the favorites.
        $actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // Ensure we attempt to update after signing in.
        // This would be significnatly improved by changing the GitHub client authentication flow.
        client.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Check for updates every minute to ensure the app feels live and responsive.
        // In the future, it would make sense to reduce this frequency if there are no active windows or if the app is
        // running in the background.
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.refresh()
            }
            .store(in: &cancellables)

    }

    @MainActor func cancel() {
        cancellables.removeAll()
    }

    // TODO: Move this into the client?
    func update(action: Action) async throws -> ActionStatus {
        let workflowRuns = try await client.workflowRuns(for: action.repositoryFullName)
        // TODO: Make a faulting filter.

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

        // TODO: Can I do async map?
        var annotations: [GitHub.Annotation] = []
        for workflowJob in workflowJobs {
            annotations.append(contentsOf: try await client.annotations(for: action.repositoryFullName,
                                                                        workflowJob: workflowJob))
        }

        return ActionStatus(action: action, workflowRun: latestRun, annotations: annotations)
    }

    func refresh() {
        dispatchPrecondition(condition: .onQueue(.main))
        for action in actions {
            Task {
                do {
                    let status = try await update(action: action)
                    print(status)
                    DispatchQueue.main.async {
                        self.cachedStatus[action] = status
                    }
                } catch {
                    print("Failed to update with error \(error).")
                }
                lastUpdate = Date()
            }
        }
    }

}
