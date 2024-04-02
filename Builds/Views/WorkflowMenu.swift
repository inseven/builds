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

fileprivate extension ApplicationModel {

    var openMenuItemSystemImage: String {
        if useInAppBrowser {
            return "arrow.up.forward.square"
        } else {
            return "safari"
        }
    }

}

struct WorkflowMenu {

    @MainActor @MenuItemBuilder static func items(applicationModel: ApplicationModel,
                                                  sceneModel: SceneModel?,
                                                  selection: Set<WorkflowInstance.ID>,
                                                  openContext: OpenContext) -> [MenuItem] {

        let workflowInstances = sceneModel?.workflows.filter(selection: selection) ?? []
        let results = workflowInstances.compactMap { $0.result }

        MenuItem("Get Info", systemImage: "info") {
            for instance in workflowInstances {
#if os(macOS)
                openContext.openWindow(id: "info", value: instance.id)
#else
                sceneModel?.settings.sheet = .view(instance.id)
#endif
            }
        }
        .keyboardShortcut("i")
        .disabled(results.isEmpty)

        Divider()

        MenuItem("Open") {

            MenuItem("Run", systemImage: applicationModel.openMenuItemSystemImage) {
                for result in results {
                    openContext.presentURL(result.workflowRun.html_url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Commit", systemImage: applicationModel.openMenuItemSystemImage) {
                for url in workflowInstances.compactMap({ $0.commitURL }) {
                    openContext.presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Workflow", systemImage: applicationModel.openMenuItemSystemImage) {
                for url in workflowInstances.compactMap({ $0.workflowURL }) {
                    openContext.presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Branch", systemImage: applicationModel.openMenuItemSystemImage) {
                for url in Set(workflowInstances.compactMap({ $0.branchURL })) {
                    openContext.presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Pulls", systemImage: applicationModel.openMenuItemSystemImage) {
                for url in workflowInstances.compactMap({ $0.pullsURL }) {
                    openContext.presentURL(url)
                }
            }
            .disabled(results.isEmpty)

            MenuItem("Repository", systemImage: applicationModel.openMenuItemSystemImage) {
                for url in Set(workflowInstances.compactMap({ $0.repositoryURL })) {
                    openContext.presentURL(url)
                }
            }
            .disabled(results.isEmpty)

        }
        .disabled(results.isEmpty)

        Divider()

        MenuItem("Remove \(workflowInstances.count) Workflows", systemImage: "trash", role: .destructive) {
            for workflowInstance in workflowInstances {
                applicationModel.removeFavorite(workflowInstance.id)
            }
        }
        .disabled(workflowInstances.isEmpty)

    }

}
