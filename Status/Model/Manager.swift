//
//  Manager.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Combine
import SwiftUI

@MainActor
class Manager: ObservableObject {

    let settings: Settings
    let client: GitHubClient

    var settingsSink: Cancellable?
    var clientSink: Cancellable?

    // TODO: Annotate for main actor?
    @Published var cachedStatus: [Action: ActionStatus] = [:]

    var status: [ActionStatus] {
        return settings.actions.map { action in
            guard let status = cachedStatus[action] else {
                return ActionStatus(action: action, workflowRun: nil)
            }
            return status
        }
    }

    init(settings: Settings, authentication: Binding<GitHub.Authentication?>) {
        self.settings = settings
        let configuration = Bundle.main.configuration()
        let api = GitHub(clientId: configuration.clientId,
                         clientSecret: configuration.clientSecret,
                         redirectUri: "http://127.0.0.1")
        self.client = GitHubClient(api: api, authentication: authentication)
        settingsSink = settings.objectWillChange.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.refresh()
        })
        clientSink = client.objectWillChange.sink(receiveValue: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.objectWillChange.send()
        })
    }

    // TODO: Move this into the client?
    func update(action: Action) async throws -> ActionStatus {
        let workflowRuns = try await client.workflowRuns(for: action.repositoryName)
        // TODO: Make a faulting filter.
        print(workflowRuns)

        let latestRun = workflowRuns.first { workflowRun in
            if workflowRun.workflowId != action.workflowId {
                return false
            }
            if let branch = action.branch {
                return workflowRun.headBranch == branch
            }
            return true
        }

        return ActionStatus(action: action, workflowRun: latestRun)
    }

    func addAction(_ action: Action) {
        settings.addAction(action)
    }

    func removeAction(_ action: Action) {
        settings.removeAction(action)
    }

    func refresh() {
        dispatchPrecondition(condition: .onQueue(.main))
        for action in settings.actions {
            Task {
                do {
                    let status = try await update(action: action)
                    print(status)
                    DispatchQueue.main.async {
                        self.cachedStatus[action] = status
                    }
                } catch {
                    print("FAILED WITH ERROR")
                }
            }
        }
    }

}
