// Copyright (c) 2021-2025 Jason Morley
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

struct WorkflowsDetailView: View {

    @ObservedObject var applicationModel: ApplicationModel

    var sceneModel: SceneModel

    var body: some View {
        VStack {
            if let section = sceneModel.settings.section {
                WorkflowsSection(applicationModel: applicationModel, sceneModel: sceneModel, section: section)
                    .id(section)
            } else {
                ContentUnavailableView {
                    Label("Nothing Selected", systemImage: "sidebar.leading")
                } description: {
                    Text("Select a section from the sidebar to view workflows.")
                }
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(sceneModel.settings.section?.title ?? "")
#if os(macOS)
        .navigationSubtitle("\(sceneModel.workflows.count) Workflows")
#endif
        .toolbar(id: "main") {

            ToolbarItem(id: "manage-workflows", placement: .primaryAction) {
                Button {
                    sceneModel.manageWorkflows()
                } label: {
                    Label("Add Workflows", systemImage: "plus")
                }
                .help("Select workflows to display")
                .disabled(!applicationModel.isSignedIn)
            }

#if os(macOS)

            if applicationModel.isSignedIn && (applicationModel.isUpdating || applicationModel.lastError != nil) {
                ToolbarItem(id: "status", placement: .navigation) {
                    StatusButton(applicationModel: applicationModel, sceneModel: sceneModel)
                }
                .customizationBehavior(.disabled)
            }

#endif

#if DEBUG

            ToolbarItem(id: "break-auth", placement: .primaryAction) {
                Menu {
                    Button {
                        await applicationModel.simulateFailure(.authentication)
                    } label: {
                        Label("Simulate Authentication Failure", systemImage: "person.slash")
                    }
                } label: {
                    Label("Simulate Failure", systemImage: "ladybug")
                }
            }

#endif

        }
    }

}
