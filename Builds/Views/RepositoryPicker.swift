//
//  RepositoriesView.swift
//  Status
//
//  Created by Jason Barrie Morley on 02/04/2022.
//

import SwiftUI

struct RepositoryPicker: View {

    @EnvironmentObject var manager: Manager

    @Environment(\.presentationMode) var presentationMode

    @State var repositories: [GitHub.Repository]? = nil
    @State var error: Error?

    @Binding var selection: GitHub.Repository?

    func fetch() {
        Task {
            do {
                let content = try await manager.client
                    .repositories()
                    .sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
                DispatchQueue.main.async {
                    self.repositories = content
                }
                print("content = \(content)")
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }

    var body: some View {
        VStack {
            if let repositories = repositories {
                List {
                    ForEach(repositories) { repository in
                        Button {
                            selection = repository
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            // TODO: Consider using a label?
                            HStack {
                                AsyncImage(url: repository.owner.avatar_url) { image in
                                    image
                                        .resizable()
                                        .clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person")
                                }
                                .frame(width: 44, height: 44)
                                Text(repository.fullName)
                            }
                        }
                    }
                }

                .listStyle(.plain)
            } else {
                ProgressView()
            }

        }
        .navigationTitle("Repository")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert(error?.localizedDescription ?? "None", isPresented: $error.mappedToBool(), actions: {
            Button("OK") {}
        })
        .onAppear {
            // TODO: Task?
            fetch()
        }
    }

    // TODO: Refreshable

}
