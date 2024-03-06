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

struct WorkflowsView: View {

    @EnvironmentObject var applicationModel: ApplicationModel

    @Environment(\.openURL) var openURL

    let workflows: [WorkflowInstance]

    private var layout = [GridItem(.adaptive(minimum: 300))]

    init(workflows: [WorkflowInstance]) {
        self.workflows = workflows
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: layout) {
                ForEach(workflows) { instance in
                    WorkflowInstanceCell(instance: instance)
                        .contextMenu {
                            Button {
                                guard let workflowRun = instance.result?.workflowRun else {
                                    return
                                }
                                openURL(workflowRun.htmlURL)
                            } label: {
                                Text("Open")
                            }
                            Divider()
                            Button(role: .destructive) {
                                applicationModel.removeFavorite(instance.id)
                            } label: {
                                Label("Remove Workflow", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            guard let workflowRun = instance.result?.workflowRun else {
                                return
                            }
                            openURL(workflowRun.htmlURL)
                        }

                }
            }
            .padding()
        }
        .refreshable {
            await applicationModel.refresh()
        }
#if os(macOS)
        .navigationSubtitle("\(applicationModel.results.count) Workflows")
#endif
        .frame(minWidth: 300, minHeight: 300)
    }

}
