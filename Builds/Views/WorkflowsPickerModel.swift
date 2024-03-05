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

class WorkflowPickerModel: ObservableObject, Runnable {

    @Published var workflow: GitHub.Workflow?
    @Published var branch: GitHub.Branch?
    @MainActor @Published var actions: [ConcreteWorkflowDetails] = []

    private let applicationModel: ApplicationModel
    let repositoryDetails: RepositoryDetails
    private var cancellables = Set<AnyCancellable>()

    init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        self.repositoryDetails = repositoryDetails
        self.workflow = repositoryDetails.workflows.first
        self.branch = repositoryDetails.branches.first { repositoryDetails.repository.defaultBranch == $0.name }
    }

    @MainActor func start() {
        applicationModel
            .$favorites
            .map { actions in
                return actions
                    .filter { action in
                        return action.repositoryFullName == self.repositoryDetails.repository.fullName
                    }
                    .map { action in
                        let workflow = self.repositoryDetails.workflows.first(where: { $0.id == action.workflowId })
                        return ConcreteWorkflowDetails(name: workflow?.name ?? String(action.workflowId),
                                                       branch: action.branch)
                    }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.actions, on: self)
            .store(in: &cancellables)
    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

    @MainActor func add() {
        guard let workflow = workflow,
              let branch = branch else {
            return
        }
        let action = WorkflowInstance.Identifier(repositoryFullName: repositoryDetails.repository.fullName,
                                                 workflowId: workflow.id,
                                                 branch: branch.name)
        applicationModel.addAction(action)
    }

}
