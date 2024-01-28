//
//  RepositoryView.swift
//  Status
//
//  Created by Jason Barrie Morley on 01/04/2022.
//

import SwiftUI

struct WorkflowRunsView: View {

    var client: GitHub
    var repository: Repository

    @State var workflowRuns: [WorkflowRun] = []

    func fetch() {
        Task {
            do {
                let workflowRuns = try await client.workflowRuns(for: repository)
                DispatchQueue.main.async {
                    self.workflowRuns = workflowRuns
                }
                print("workflow runs = \(workflowRuns)")
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    var body: some View {
        List {
            ForEach(workflowRuns) { workflowRun in
                HStack {
                    Text(workflowRun.name)
                    Spacer()
                    Text(workflowRun.status)
                }
            }
        }
        .navigationTitle("Select Action")
        .onAppear {
            fetch()
        }
    }

}
