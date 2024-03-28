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

struct WorkflowsSection: View {

    struct LayoutMetrics {
#if os(macOS)
        static let symbolSize = 46.0  // 41.0 matches SF Symbols but feels too small.
#else
        static let symbolSize = 54.5
#endif
    }

    @ObservedObject var applicationModel: ApplicationModel
    @ObservedObject var sceneModel: SceneModel

    let section: SectionIdentifier

    var body: some View {
        VStack {
            if applicationModel.isAuthorized {
                if applicationModel.results.count > 0 {
                    WorkflowsView(workflows: sceneModel.workflows)
#if os(macOS)
                        .safeAreaInset(edge: .bottom) {
                            VStack(spacing: 0) {
                                Divider()
                                HStack {
                                    if applicationModel.isUpdating {
                                        Text("Updating...")
                                    } else if let lastError = applicationModel.lastError {
                                        Label(lastError.localizedDescription, systemImage: "exclamationmark.fill")
                                            .symbolRenderingMode(.multicolor)
                                    } else if let lastUpdate = applicationModel.lastUpdate {
                                        Text(lastUpdate, style: .time)
                                    } else {
                                        Text("Never Updated")
                                    }
                                }
                                .padding()
                            }
                            .foregroundStyle(.secondary)
                            .background(.thinMaterial)
                        }
#endif
                } else {
                    ContentUnavailableView {
                        Label("No Workflows", systemImage: "checklist.unchecked")
                    } description: {
                        Text("Add workflows to view their statuses.")
                    } actions: {
                        Button {
                            sceneModel.manageWorkflows()
                        } label: {
                            Text("Manage Workflows")
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label {
                        Text("Sign In")
                    } icon: {
                        SVGImage(url: Bundle.main.url(forResource: "github-mark", withExtension: "svg")!)
                            .frame(width: LayoutMetrics.symbolSize, height: LayoutMetrics.symbolSize)
                    }
                } description: {
                    Text("Builds uses your GitHub account to retrieve information about your GitHub Actions workflow statuses.")
                } actions: {
                    Button {
                        sceneModel.logIn()
                    } label: {
                        Text("Sign In with GitHub")
                    }
                }
            }
        }
        .navigationTitle(section.title)
        .toolbarTitleDisplayMode(.inline)
    }

}
