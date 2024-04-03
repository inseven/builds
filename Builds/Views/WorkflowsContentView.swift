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

import Interact

struct WorkflowsContentView: View {

#if os(macOS)
    @Environment(\.controlActiveState) var controlActiveState
#endif

    @ObservedObject var applicationModel: ApplicationModel

    @StateObject var workflowsModel: WorkflowsModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _workflowsModel = StateObject(wrappedValue: WorkflowsModel(applicationModel: applicationModel))
    }

    var body: some View {
        VStack {
            if let repositories = workflowsModel.repositories {
                Form {
                    ForEach(repositories) { repository in
                        WorkflowPicker(applicationModel: applicationModel, repositoryDetails: repository)
                    }
                }
                .formStyle(.grouped)
            } else {
#if os(macOS)
                ContentUnavailableView {
                    Text("Loading...")
                }
#else
                ProgressView()
#endif
            }
        }
        .navigationTitle("Add Workflows")
        .toolbarTitleDisplayMode(.inline)
#if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    await workflowsModel.refresh()
                } label: {
                    if workflowsModel.isUpdating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(workflowsModel.repositories == nil)
            }
        }
#else
        .refreshable {
            await workflowsModel.refresh()
        }
#endif
        .dismissable()
        .interactiveDismissDisabled()
        .runs(workflowsModel)
        .presents($workflowsModel.error)
#if os(macOS)
        .onChange(of: controlActiveState) { oldValue, newValue in
            if newValue == .key {
                Task {
                    await workflowsModel.refresh()
                }
            }
        }
#endif
    }

}
