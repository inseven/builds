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

struct WorkflowPicker: View {

    @ObservedObject var applicationModel: ApplicationModel
    @StateObject var workflowPickerModel: WorkflowPickerModel

    init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        _workflowPickerModel = StateObject(wrappedValue: WorkflowPickerModel(applicationModel: applicationModel,
                                                                             repositoryDetails: repositoryDetails))
    }

    var body: some View {
        ForEach(workflowPickerModel.repositoryDetails.workflows) { workflow in

            let id = WorkflowInstance.ID(repositoryFullName: workflowPickerModel.repositoryDetails.repository.fullName,
                                             workflowId: workflow.id,
                                             branch: workflowPickerModel.repositoryDetails.repository.defaultBranch)

            Toggle("\(workflow.name) (\(workflowPickerModel.repositoryDetails.repository.defaultBranch))", isOn: Binding(get: {
                return applicationModel.favorites.contains(id)
            }, set: { isOn in
                if isOn {
                    applicationModel.addFavorite(id)
                } else {
                    applicationModel.removeFavorite(id)
                }
            }))
        }
        .runs(workflowPickerModel)
    }

}
