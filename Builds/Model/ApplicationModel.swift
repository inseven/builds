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

@MainActor
class ApplicationModel: ObservableObject {

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
        .sorted { $0.action.repositoryName.localizedStandardCompare($1.action.repositoryName) == .orderedAscending }
    }

    init(settings: Settings, authentication: Binding<GitHub.Authentication?>) {
        self.settings = settings
        let configuration = Bundle.main.configuration()
        let api = GitHub(clientId: configuration.clientId,
                         clientSecret: configuration.clientSecret,
                         redirectUri: "x-builds-auth://oauth")
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
