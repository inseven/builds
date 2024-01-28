//
//  WorkflowsView.swift
//  Status
//
//  Created by Jason Barrie Morley on 01/04/2022.
//

import SwiftUI

struct BranchPicker: View {

    var repository: GitHub.Repository

    @EnvironmentObject var manager: Manager

    @Environment(\.presentationMode) var presentationMode

    // TODO: Change the spinner?

    @State var branches: [GitHub.Branch]? = nil
    @Binding var selection: GitHub.Branch?

    func fetch() {
        Task {
            do {
                let branches = try await manager.client.branches(for: repository)
                DispatchQueue.main.async {
                    self.branches = branches
                }
                print("branches = \(branches)")
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    var body: some View {
        List {
            Section {
                if let branches = branches {
                    ForEach(branches) { workflow in
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
