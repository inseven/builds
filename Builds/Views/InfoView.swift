// Copyright (c) 2021-2025 Jason Morley
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

struct InfoView: View {

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
                            if let workflowRunURL = workflowInstance.workflowRunURL {
                                presentURL(workflowRunURL)
                            }
                        } label: {
                            if let title = workflowInstance.attributedTitle {
                                Text(title)
                                    .foregroundStyle(.link)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text("-")
                            }
                        }
                        .disabled(workflowInstance.workflowRunURL == nil)
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
                            if let sha = workflowInstance.shortSha {
                                Text(sha)
                                    .foregroundStyle(.link)
                                    .monospaced()
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text("-")
                            }
                        }
                        .disabled(workflowInstance.commitURL == nil)
                    } label: {
                        Text("Commit")
                    }

                    // Branch.
                    LabeledContent {
                        Button {
                            guard let brancheURL = workflowInstance.branchURL else {
                                return
                            }
                            presentURL(brancheURL)
                        } label: {
                            Text(workflowInstance.id.branch)
                                .foregroundStyle(.link)
                                .monospaced()
                                .multilineTextAlignment(.trailing)
                        }
                        .disabled(workflowInstance.branchURL == nil)
                    } label: {
                        Text("Branch")
                    }

                    // Workflow.
                    LabeledContent {
                        Button {
                            guard let workflowURL = workflowInstance.workflowFileURL else {
                                return
                            }
                            presentURL(workflowURL)
                        } label: {
                            if let workflowFilePath = workflowInstance.workflowFilePath {
                                Text(workflowFilePath)
                                    .foregroundStyle(.link)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text("-")
                            }
                        }
                        .disabled(workflowInstance.workflowFileURL == nil)
                    } label: {
                        Text("Workflow")
                    }

                }

                Section {

                    // Repository.
                    LabeledContent {
                        Button {
                            guard let url = workflowInstance.repositoryURL else {
                                return
                            }
                            presentURL(url)
                        } label: {
                            Text(workflowInstance.id.repositoryName)
                                .foregroundStyle(.link)
                                .multilineTextAlignment(.trailing)
                        }
                        .disabled(workflowInstance.repositoryURL == nil)
                    } label: {
                        Text("Repository")
                    }

                    // Organization.
                    LabeledContent {
                        Button {
                            guard let url = workflowInstance.organizationURL else {
                                return
                            }
                            presentURL(url)
                        } label: {
                            Text(workflowInstance.id.organization)
                                .foregroundStyle(.link)
                                .multilineTextAlignment(.trailing)
                        }
                        .disabled(workflowInstance.organizationURL == nil)
                    } label: {
                        Text("Organization")
                    }

                }
                Section {
                    LabeledContent {
                        if let createdAt = workflowInstance.createdAt {
                            Text(format(date: createdAt))
                        }
                    } label: {
                        Text("Created")
                    }
                    LabeledContent {
                        if let updatedAt = workflowInstance.updatedAt {
                            Text(format(date: updatedAt))
                        }
                    } label: {
                        Text("Updated")
                    }
                    LabeledContent {
                        if let runAttempt = workflowInstance.workflowRunAttempt {
                            Text("#\(runAttempt)")
                        }
                    } label: {
                        Text("Attempt")
                    }
                } header: {
                    Text("Details")
                }
                Section {
                    WorkflowJobList(jobs: workflowInstance.jobs)
                } header: {
                    Text("Jobs")
                }
                if !workflowInstance.annotations.isEmpty {
                    Section {
                        AnnotationList(workflowInstance: workflowInstance)
                    } header: {
                        Text("Annotations")
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
        .requestsHigherFrequencyUpdates()
    }

}
