//
//  ActionWizard.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

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
