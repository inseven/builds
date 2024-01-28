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
