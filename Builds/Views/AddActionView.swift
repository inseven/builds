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

struct AddActionView: View {

    @Environment(\.dismiss) var dismiss

    let applicationModel: ApplicationModel

    @StateObject var model: AddActionModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _model = StateObject(wrappedValue: AddActionModel(applicationModel: applicationModel))
    }

    var body: some View {
        Form {

            // Repository
            if let repositories = model.repositories {
                Picker("Repository", selection: $model.repository) {
                    ForEach(repositories) { repository in
                        Text(repository.fullName)
                            .tag(repository as GitHub.Repository?)
                    }
                }
#if os(iOS)
                        .pickerStyle(NavigationLinkPickerStyle())
#endif
            } else {
                LabeledContent {
                    ProgressView()
                        .controlSize(.small)
                } label: {
                    Text("Repository")
                }
            }

            Section {

                // Workflow
                if let workflows = model.workflows {
                    if !workflows.isEmpty {
                        Picker("Workflow", selection: $model.workflow) {
                            ForEach(workflows) { workflow in
                                Text(workflow.name)
                                    .tag(workflow as GitHub.Workflow?)
                            }
                        }
#if os(iOS)
                        .pickerStyle(NavigationLinkPickerStyle())
#endif
                    } else {
                        LabeledContent {
                            Text("None")
                        } label: {
                            Text("Workflow")
                        }
                    }
                } else {
                    LabeledContent {
                        ProgressView()
                            .controlSize(.small)
                    } label: {
                        Text("Workflow")
                    }
                }

                // Branch
                if let branches = model.branches {
                    Picker("Branch", selection: $model.branch) {
                        ForEach(branches) { branch in
                            Text(branch.name)
                                .tag(branch as GitHub.Branch?)
                        }
                    }
#if os(iOS)
                        .pickerStyle(NavigationLinkPickerStyle())
#endif

                } else {
                    LabeledContent {
                        ProgressView()
                            .controlSize(.small)
                    } label: {
                        Text("Branch")
                    }
                }

            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add")
        .presents($model.error)
        .onAppear {
            model.start()
        }
        .onDisappear {
            model.stop()
        }
#if os(macOS)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Add") {
                    model.add()
                    dismiss()
                }
                .disabled(!model.canAdd)
            }
            .padding()
        }
#else
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    model.add()
                    dismiss()
                }
                .disabled(!model.canAdd)
            }
        }
#endif
    }

}
