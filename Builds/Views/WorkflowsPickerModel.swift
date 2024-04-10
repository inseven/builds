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

import BuildsCore

class WorkflowPickerModel: ObservableObject, Runnable {

    struct WorkflowDetails: Identifiable {

        var id: String {
            return "\(workflowId)@\(branch)"
        }

        let workflowId: Int
        let workflowName: String
        let branch: String
    }

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case add
    }

    @Published var workflows: [GitHub.Workflow]
    @Published var branch: GitHub.Branch?
    @MainActor @Published var actions: [WorkflowDetails] = []
    @MainActor @Published var branches: [String] = []
    @MainActor @Published var extraBranches: [String] = []
    @MainActor @Published var add: String? = nil
    @MainActor @Published var sheet: SheetType?

    private let applicationModel: ApplicationModel
    let repositoryDetails: RepositoryDetails
    private var cancellables = Set<AnyCancellable>()

    @MainActor init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        self.repositoryDetails = repositoryDetails
        self.workflows = repositoryDetails.workflows
        self.branch = repositoryDetails.branches.first { repositoryDetails.repository.default_branch == $0.name }
        self.branches = [repositoryDetails.repository.default_branch]
    }

    @MainActor func start() {

        // Ensure we show branches for all workflows that have been saved.
        applicationModel
            .$workflows
            .map { workflows in
                return workflows.filter { workflow in
                    workflow.repositoryFullName == self.repositoryDetails.repository.full_name
                }.reduce(into: Set<String>()) { partialResult, id in
                    partialResult.insert(id.branch)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { branches in
                for branch in branches {
                    if !self.branches.contains(branch) {
                        self.branches.append(branch)
                    }
                }
            }
            .store(in: &cancellables)

        // Generate the matrix of workflows and branches.
        $branches
            .map { branches in
                return branches.map { branch in
                    return self.workflows
                        .map { workflow in
                            return WorkflowDetails(workflowId: workflow.id,
                                                           workflowName: workflow.name,
                                                           branch: branch)
                        }
                }
                .reduce([], +)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.actions, on: self)
            .store(in: &cancellables)

        // Generate the list of extra branches.
        $branches
            .map { branches in
                return Set(self.repositoryDetails.branches.map { $0.name })
                    .subtracting(branches)
                    .sorted()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.extraBranches, on: self)
            .store(in: &cancellables)

        // Watch for new branches.
        $add
            .compactMap { branch in
                return branch
            }
            .receive(on: DispatchQueue.main)
            .sink { branch in
                self.branches.append(branch)
            }
            .store(in: &cancellables)

    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

}
