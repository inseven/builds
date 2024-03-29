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

import Interact
import SelectableCollectionView

struct WorkflowsView: View {

    struct LayoutMetrics {
        static let interItemSpacing: CGFloat? = 10.0
    }

    @Environment(\.openWindow) private var openWindow
    @Environment(\.presentURL) private var presentURL

    @EnvironmentObject private var applicationModel: ApplicationModel
    @EnvironmentObject private var sceneModel: SceneModel

    let workflows: [WorkflowInstance]

    private var columns = [GridItem(.adaptive(minimum: 300))]

    init(workflows: [WorkflowInstance]) {
        self.workflows = workflows
    }

    var body: some View {
        SelectableCollectionView(workflows, selection: $sceneModel.selection,
                                 columns: columns,
                                 spacing: LayoutMetrics.interItemSpacing) { workflowInstance in
            WorkflowInstanceCell(instance: workflowInstance)
#if os(iOS)
                .environment(\.isSelected, sceneModel.selection.contains(workflowInstance.id))
#endif
        } contextMenu: { selection in

            let workflowInstances = workflows.filter(selection: selection)
            let results = workflowInstances.compactMap { $0.result }

#if os(macOS)

            MenuItem("Get Info", systemImage: "info") {
                for instance in workflowInstances {
                    openWindow(id: "info", value: instance.id)
                }
            }

            Divider()

#endif

            MenuItem("Open Run", systemImage: "safari") {
                for result in results {
                    presentURL(result.workflowRun.html_url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Open Commit", systemImage: "safari") {
                for url in workflowInstances.compactMap({ $0.commitURL }) {
                    presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Open Repository", systemImage: "safari") {
                for url in workflowInstances.compactMap({ $0.repositoryURL }) {
                    presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            Divider()

            MenuItem("Remove \(workflowInstances.count) Workflows", systemImage: "trash", role: .destructive) {
                for workflowInstance in workflowInstances {
                    applicationModel.removeFavorite(workflowInstance.id)
                }
            }
            .disabled(workflowInstances.isEmpty)

        } primaryAction: { selection in
#if os(macOS)
            let workflowInstances = workflows.filter(selection: selection)
            for result in workflowInstances.compactMap({ $0.result }) {
                presentURL(result.workflowRun.html_url)
            }
#else
            guard let id = selection.first?.id else {
                return
            }
            sceneModel.sheet = .view(id)
#endif
        }
        .frame(minWidth: 300)

#if os(macOS)
        .navigationSubtitle("\(workflows.count) Workflows")
#endif
        .refreshable {
            await applicationModel.refresh()
        }
    }

}
