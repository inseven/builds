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

extension GitHub.WorkflowJob: Identifiable {

    var color: Color {
        return SummaryState(status: status, conclusion: conclusion).color
    }

}

struct WorkflowInspector: View {

    @EnvironmentObject var applicationModel: ApplicationModel

    @Environment(\.openURL) var openURL

    let workflowInstance: WorkflowInstance

    func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(workflowInstance.id.repositoryFullName)
                } label: {
                    Text("Repository")
                }
                LabeledContent {
                    Text(workflowInstance.workflowName)
                } label: {
                    Text("Workflow")
                }
                LabeledContent {
                    Text(workflowInstance.id.branch)
                } label: {
                    Text("Branch")
                }
            }
            if let result = workflowInstance.result {
                Section {
                    LabeledContent {
                        Text(format(date: result.workflowRun.createdAt))
                    } label: {
                        Text("Created")
                    }
                    LabeledContent {
                        Text(format(date: result.workflowRun.updatedAt))
                    } label: {
                        Text("Updated")
                    }
                    LabeledContent {
                        let runAttempt = result.workflowRun.runAttempt
                        Text("#\(runAttempt)")
                    } label: {
                        Text("Attempt")
                    }
                } header: {
                    Text("Details")
                }
                Section {
                    ForEach(result.jobs) { job in
                        Button {
                            openURL(job.html_url)
                        } label: {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .renderingMode(.template)
                                    .foregroundStyle(job.color)
                                Text(job.name)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Jobs")
                }
            }
            if !workflowInstance.annotations.isEmpty {
                Section {
                    ForEach(workflowInstance.annotations) { annotation in
                        HStack(alignment: .firstTextBaseline) {
                            if annotation.annotation_level == "warning" {
                                Image(systemName: "exclamationmark.triangle")
                            }
                            VStack(alignment: .leading) {
                                Text("Unknown Job")
                                    .fontWeight(.bold)
                                Text(annotation.message)
                                    .lineLimit(10)
                                    .monospaced()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Annotations")
                }
            }
        }
        .formStyle(.grouped)
    }

}