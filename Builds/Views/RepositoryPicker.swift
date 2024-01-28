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
