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

struct WorkflowRunsView: View {

    let repository: GitHub.Repository
    let workflow: GitHub.Workflow?

    let dateFormatter: RelativeDateTimeFormatter = {
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter
    }()

    @EnvironmentObject var client: GitHubClient
    @State var workflowRuns: [GitHub.WorkflowRun] = []

    init(repository: GitHub.Repository, workflow: GitHub.Workflow? = nil) {
        self.repository = repository
        self.workflow = workflow
    }

    // TODO: Bot runs don't turn up?

    func fetch() {
        Task {
            do {
                let workflowRuns = try await client.workflowRuns(for: repository.fullName)
                    .filter { workflowRun in
                        guard let workflow = workflow else {
                            return true
                        }
                        return workflowRun.workflowId == workflow.id
                    }
                DispatchQueue.main.async {
                    self.workflowRuns = workflowRuns
                }
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    var body: some View {
        List {
            ForEach(workflowRuns) { workflowRun in
                HStack {
                    if let conclusion = workflowRun.conclusion {
                        switch conclusion {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.systemGreen))
                        case .failure:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(workflowRun.name)
                        HStack {
                            Text("#\(String(workflowRun.runNumber))")
                            Text(workflowRun.headBranch)
                            Text(workflowRun.headSha.prefix(8))
                        }
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(dateFormatter.localizedString(for: workflowRun.createdAt, relativeTo: Date()))
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Workflow Runs")
                        .font(.headline)
                    Text(repository.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            fetch()
        }
    }

}
