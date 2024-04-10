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

import BuildsCore

struct WorkflowsView: View, OpenContext {

    struct LayoutMetrics {
        static let interItemSpacing: CGFloat? = 10.0
    }

    @Environment(\.openWindow) var openWindow
    @Environment(\.presentURL) var presentURL

    @EnvironmentObject private var applicationModel: ApplicationModel
    @Environment(SceneModel.self) var sceneModel

    let workflows: [WorkflowInstance]

    private var columns = [GridItem(.adaptive(minimum: 300))]

    init(workflows: [WorkflowInstance]) {
        self.workflows = workflows
    }

    var body: some View {
        @Bindable var sceneModel = sceneModel
        SelectableCollectionView(workflows, selection: $sceneModel.selection,
                                 columns: columns,
                                 spacing: LayoutMetrics.interItemSpacing) { workflowInstance in
            WorkflowInstanceCell(instance: workflowInstance)
#if os(iOS)
                .environment(\.isSelected, sceneModel.selection.contains(workflowInstance.id))
#endif
        } contextMenu: { selection in
            WorkflowMenu.items(applicationModel: applicationModel,
                               sceneModel: sceneModel,
                               selection: selection,
                               openContext: self)
        } primaryAction: { selection in
#if os(macOS)
            let workflowInstances = workflows.filter(selection: selection)
            for result in workflowInstances.compactMap({ $0.result }) {
                presentURL(result.workflowRun.html_url)
            }
#else
            guard let id = selection.first else {
                return
            }
            sceneModel.settings.sheet = .view(id)
#endif
        }
        .frame(minWidth: 300)
        .presents($sceneModel.error)
        .refreshable {
            await applicationModel.refresh()
        }
    }

}
