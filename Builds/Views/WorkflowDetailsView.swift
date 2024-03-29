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

struct WorkflowDetailsView: View {

    @Environment(\.presentURL) private var presentURL

    @State private var model: WorkflowInspectorModel

    private let id: WorkflowInstance.ID

    init(applicationModel: ApplicationModel, id: WorkflowInstance.ID) {
        self.id = id
        self._model = State(initialValue: WorkflowInspectorModel(applicationModel: applicationModel, id: id))
    }

    func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        Form {
            if let workflowInstance = model.workflowInstance {
                Section {

                    // Title.
                    LabeledContent {
                        Button {
                            if let result = workflowInstance.result {
                                presentURL(result.workflowRun.html_url)
                            }
                        } label: {
                            if let title = workflowInstance.attributedTitle {
                                Text(title)
                                    .foregroundStyle(.link)
                            } else {
                                Text("-")
                            }
                        }
                        .disabled(workflowInstance.result == nil)
                    } label: {
                        Text("Title")
                    }

                    // Commit.
                    LabeledContent {
                        Button {
                            guard let url = workflowInstance.commitURL else {
                                return
                            }
                            presentURL(url)
                        } label: {
                            if let sha = workflowInstance.sha {
                                Text(sha)
                                    .foregroundStyle(.link)
                                    .monospaced()
                            } else {
                                Text("-")
                            }
                        }
                        .disabled(workflowInstance.result == nil)
                    } label: {
                        Text("Commit")
                    }

                    // Branch.
                    LabeledContent {
                        Text(workflowInstance.id.branch)
                    } label: {
                        Text("Branch")
                    }

                    // Workflow.
                    LabeledContent {
                        Text(workflowInstance.workflowName)
                    } label: {
                        Text("Workflow")
                    }

                    // Repository.
                    LabeledContent {
                        Button {
                            guard let url = workflowInstance.repositoryURL else {
                                return
                            }
                            presentURL(url)
                        } label: {
                            Text(workflowInstance.id.repositoryFullName)
                                .foregroundStyle(.link)
                        }
                        .disabled(workflowInstance.repositoryURL == nil)
                    } label: {
                        Text("Repository")
                    }

                }
                if let result = workflowInstance.result {
                    Section {
                        LabeledContent {
                            Text(format(date: result.workflowRun.created_at))
                        } label: {
                            Text("Created")
                        }
                        LabeledContent {
                            Text(format(date: result.workflowRun.updated_at))
                        } label: {
                            Text("Updated")
                        }
                        LabeledContent {
                            let runAttempt = result.workflowRun.run_attempt
                            Text("#\(runAttempt)")
                        } label: {
                            Text("Attempt")
                        }
                    } header: {
                        Text("Details")
                    }
                    Section {
                        WorkflowJobList(jobs: result.jobs)
                    } header: {
                        Text("Jobs")
                    }
                    if !result.annotations.isEmpty {
                        Section {
                            AnnotationList(result: result)
                        } header: {
                            Text("Annotations")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .buttonStyle(.plain)
        .navigationTitle(model.workflowInstance?.repositoryName ?? "")
#if os(macOS)
        .navigationSubtitle(model.workflowInstance?.workflowName ?? "")
#endif
        .toolbarTitleDisplayMode(.inline)
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(model.workflowInstance?.repositoryName ?? "")
                        .font(.headline)
                    Text(model.workflowInstance?.workflowName ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
#endif
        .dismissable(placement: .cancellationAction)
    }

}
