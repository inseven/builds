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

struct ActionWizard: View {

    @EnvironmentObject var manager: Manager

    @Environment(\.dismiss) var dismiss

    @State var repository: GitHub.Repository?
    @State var workflow: GitHub.Workflow?
    @State var branch: GitHub.Branch?

    func add() {
        guard let repository = repository,
              let workflow = workflow
        else {
            return
        }
        let action = Action(repositoryName: repository.fullName,
                            workflowId: workflow.id,
                            branch: branch?.name)
        manager.addAction(action)
        dismiss()
    }

    var body: some View {
        Form {
            NavigationLink {
                RepositoryPicker(selection: $repository)
            } label: {
                HStack {
                    Text("Repository")
                    Spacer()
                    Text(repository?.fullName ?? "None")
                        .foregroundColor(.secondary)
                }
            }
            if let repository = repository {

                Section {

                    NavigationLink {
                        WorkflowPicker(repository: repository, selection: $workflow)
                    } label: {
                        HStack {
                            Text("Workflow")
                            Spacer()
                            Text(workflow?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        BranchPicker(repository: repository, selection: $branch)
                    } label: {
                        HStack {
                            Text("Branch")
                            Spacer()
                            Text(branch?.name ?? "Any")
                                .foregroundColor(.secondary)
                        }
                    }

                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add Action")
#if os(macOS)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Add") {
                    add()
                }
            }
            .padding()
        }
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    add()
                }
            }
        }
#endif
    }

}
