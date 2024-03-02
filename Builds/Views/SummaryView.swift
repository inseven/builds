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

struct SummaryView: View {

    @EnvironmentObject var applicationModel: ApplicationModel

    @Environment(\.openURL) var openURL

    private var layout = [GridItem(.adaptive(minimum: 300))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: layout) {
                ForEach(applicationModel.status) { status in
                    SummaryCell(status: status)
                        .contextMenu {
                            Button {
                                guard let workflowRun = status.workflowRun else {
                                    return
                                }
                                openURL(workflowRun.htmlURL)
                            } label: {
                                Text("Open")
                            }
                            Divider()
                            Button(role: .destructive) {
                                applicationModel.removeAction(status.action)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            guard let workflowRun = status.workflowRun else {
                                return
                            }
                            openURL(workflowRun.htmlURL)
                        }

                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            // TODO: Extract this.
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 0) {
                    if applicationModel.isUpdating {
                        Text("Updating...")
                    } else if let lastUpdate = applicationModel.lastUpdate {
                        Text("Last updated ")
                        Text(lastUpdate, style: .relative)
                        Text(" ago")
                    } else {
                        Text("Never updated")
                    }
                }
                .padding(8)
                .foregroundStyle(.secondary)
                .font(.footnote)
            }
        }
    }

}
