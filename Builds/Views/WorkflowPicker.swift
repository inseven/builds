//
//  WorkflowsView.swift
//  Status
//
//  Created by Jason Barrie Morley on 01/04/2022.
//

import SwiftUI

struct WorkflowPicker: View {

    var repository: GitHub.Repository

    @EnvironmentObject var manager: Manager

    @Environment(\.presentationMode) var presentationMode

    // TODO: Change the spinner?

    @State var workflows: [GitHub.Workflow]? = nil
    @Binding var selection: GitHub.Workflow?

    func fetch() {
        Task {
            do {
                let workflows = try await manager.client.workflows(for: repository)
                DispatchQueue.main.async {
                    self.workflows = workflows
                }
                print("workflow runs = \(workflows)")
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    var body: some View {
        List {
            Section {
                if let workflows = workflows {
                    ForEach(workflows) { workflow in
                        Button(workflow.name) {
                            selection = workflow
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Workflow")
        .onAppear {
            fetch()
        }
    }

}
