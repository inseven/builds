//
//  RepositoryView.swift
//  Status
//
//  Created by Jason Barrie Morley on 01/04/2022.
//

// TODO: Indicate private repositories

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
