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

import SwiftUI

import BuildsCore

struct WorkflowPicker: View {

    @ObservedObject var applicationModel: ApplicationModel
    @StateObject var workflowPickerModel: WorkflowPickerModel

    init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        _workflowPickerModel = StateObject(wrappedValue: WorkflowPickerModel(applicationModel: applicationModel,
                                                                             repositoryDetails: repositoryDetails))
    }

    func binding(for workflow: WorkflowPickerModel.WorkflowDetails) -> Binding<Bool> {
        let id = WorkflowInstance.ID(repositoryFullName: workflowPickerModel.repositoryDetails.repository.full_name,
                                     workflowId: workflow.workflowId,
                                     workflowNodeId: workflow.workflowNodeId,
                                     workflowNameSnapshot: workflow.workflowName,
                                     branch: workflow.branch)
        return Binding {
            return applicationModel.workflows.contains(id)
        } set: { isOn in
            if isOn {
                applicationModel.addWorkflow(id)
            } else {
                applicationModel.removeWorkflow(id)
            }
        }
    }

    var body: some View {
        Section {
            ForEach(workflowPickerModel.actions) { workflow in
                Toggle(isOn: binding(for: workflow)) {
                    VStack(alignment: .leading) {
                        Text(workflow.workflowName)
                        Text(workflow.branch)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(workflowPickerModel.repositoryDetails.repository.full_name)
                .textCase(.none)
        } footer: {
#if os(macOS)
            HStack {
                Spacer()
                Menu {
                    ForEach(workflowPickerModel.extraBranches, id: \.self) { branch in
                        Button {
                            workflowPickerModel.add = branch
                        } label: {
                            Text(branch)
                        }
                    }
                } label: {
                    Text("Add Branch...")
                }
                .fixedSize(horizontal: true, vertical: false)
                .disabled(workflowPickerModel.extraBranches.count < 1)
            }
#else
            Button {
                workflowPickerModel.sheet = .add
            } label: {
                Text("Add Branch...")
            }
            .disabled(workflowPickerModel.extraBranches.count < 1)
#endif
        }
        .sheet(item: $workflowPickerModel.sheet) { sheet in
            switch sheet {
            case .add:
                BranchPickerSheet(workflowPickerModel: workflowPickerModel)
            }

        }
        .runs(workflowPickerModel)
    }

}
