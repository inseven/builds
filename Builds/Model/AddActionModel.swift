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

class AddActionModel: ObservableObject {

    let applicationModel: ApplicationModel

    @Published var repositories: [GitHub.Repository]? = nil
    @Published var repository: GitHub.Repository? = nil
    @Published var workflows: [GitHub.Workflow]? = nil
    @Published var workflow: GitHub.Workflow? = nil
    @Published var branches: [GitHub.Branch]? = nil
    @Published var branch: GitHub.Branch? = nil
    @Published var error: Error? = nil

    private var cancellables: Set<AnyCancellable> = []

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    var canAdd: Bool {
        return repository != nil && workflow != nil && branch != nil
    }

    @MainActor func add() {
        guard let repository = repository,
              let workflow = workflow,
              let branch = branch
        else {
            return
        }
        applicationModel.addAction(Action(repositoryName: repository.name,
                                          repositoryFullName: repository.fullName,
                                          workflowId: workflow.id,
                                          branch: branch.name))
    }

    func updateRepositories() {
        Task {
            do {
                let repositories = try await applicationModel.client
                    .repositories()
                    .sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
                DispatchQueue.main.async {
                    self.repositories = repositories
                    if self.repository == nil {
                        self.repository = repositories.first
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }

    func updateWorkflows(for repository: GitHub.Repository) {
        Task {
            do {
                let workflows = try await applicationModel.client.workflows(for: repository)
                DispatchQueue.main.async {
                    self.workflows = workflows
                    self.workflow = workflows.first(where: { $0.name == self.workflow?.name }) ?? workflows.first
                }
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    func updateBranches(for repository: GitHub.Repository) {
        Task {
            do {
                let branches = try await applicationModel.client.branches(for: repository)
                DispatchQueue.main.async {
                    self.branches = branches
                    self.branch = branches.first(where: { $0.name == self.branch?.name }) ?? branches.first
                }
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    func start() {

        // Look up the repositories.
        updateRepositories()

        // Fetch workflows and branches when the selection changes.
        $repository
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { repository in
                self.updateWorkflows(for: repository)
                self.updateBranches(for: repository)
            }
            .store(in: &cancellables)

    }

    func stop() {
        cancellables.removeAll()
    }

}
