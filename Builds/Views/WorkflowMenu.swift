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

import SelectableCollectionView

import BuildsCore

struct WorkflowMenu {

    @MainActor @MenuItemBuilder static func items(applicationModel: ApplicationModel,
                                                  sceneModel: SceneModel?,
                                                  selection: Set<WorkflowInstance.ID>,
                                                  openContext: OpenContext) -> [MenuItem] {

        let workflowInstances = sceneModel?.workflows.filter(selection: selection) ?? []

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
        .disabled(workflowInstances.isEmpty)

        Divider()

        MenuItem("Open", systemImage: applicationModel.useInAppBrowser ? "rectangle.and.text.magnifyingglass" : "safari") {

            // Open Run.

            let workflowRunURLs = workflowInstances
                .compactMap { $0.workflowRunURL }

            MenuItem("Run", systemImage: "play") {
                workflowRunURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(workflowRunURLs.isEmpty)

            // Open Commit.

            let commitURLs = workflowInstances
                .compactMap { $0.commitURL }

            MenuItem("Commit", systemImage: "checkmark.seal") {
                commitURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(commitURLs.isEmpty)

            // Open Branch.

            let branchURLs = workflowInstances
                .compactMap { $0.branchURL }

            MenuItem("Branch", systemImage: "arrow.turn.down.right") {
                branchURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(branchURLs.isEmpty)

            // Open Workflow.

            let workflowFileURLs = workflowInstances
                .compactMap { $0.workflowFileURL }


            MenuItem("Workflow", systemImage: "doc.text") {
                workflowFileURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(workflowFileURLs.isEmpty)

            // Divider.

            Divider()

            // Open Repository.

            let repositoryURLs = workflowInstances
                .compactMap { $0.repositoryURL }

            MenuItem("Repository", systemImage: "cylinder") {
                repositoryURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(repositoryURLs.isEmpty)

            // Open Organization.

            let organizationURLs = workflowInstances
                .compactMap { $0.organizationURL }

            MenuItem("Organization", systemImage: "building.2") {
                organizationURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(organizationURLs.isEmpty)

            // Divider.

            Divider()

            // Open Pulls.

            let pullsURLs = workflowInstances
                .compactMap { $0.pullsURL }

            MenuItem("Pulls", systemImage: "checklist") {
                pullsURLs
                    .forEach { openContext.presentURL($0) }
            }
            .disabled(pullsURLs.isEmpty)

        }
        .disabled(workflowInstances.isEmpty)

        MenuItem("Re-Run", systemImage: "memories") {

            let disabled = workflowInstances.count != 1 || workflowInstances.first?.operationState != .unknown
            let hasFailedJobs = workflowInstances.first?.jobs.contains(where: { $0.conclusion == .failure }) ?? false

            MenuItem("All Jobs", systemImage: "square.on.square") {
                Task {
                    guard let workflowInstance = workflowInstances.first,
                          let workflowRunId = workflowInstance.workflowRunId else {
                        return
                    }
                    await sceneModel?.rerun(id: workflowInstance.id, workflowRunId: workflowRunId)
                }
            }
            .disabled(disabled)

            MenuItem("Failed Jobs", systemImage: "xmark.square") {
                Task {
                    guard let workflowInstance = workflowInstances.first,
                          let workflowRunId = workflowInstance.workflowRunId else {
                        return
                    }
                    await sceneModel?.rerun(id: workflowInstance.id, workflowRunId: workflowRunId)
                }
            }
            .disabled(disabled || !hasFailedJobs)

        }

        Divider()

        MenuItem("Remove",
                 systemImage: workflowInstances.count == 1 ? "rectangle.slash" : "rectangle.on.rectangle.slash",
                 role: .destructive) {
            for workflowInstance in workflowInstances {
                applicationModel.removeWorkflow(workflowInstance.id)
            }
        }
        .disabled(workflowInstances.isEmpty)

    }

}
