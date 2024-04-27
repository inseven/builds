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

import WidgetKit

import Interact

import BuildsCore

struct SingleWorkflowTimelineProvider: AppIntentTimelineProvider {

    init() {
    }

    func workflowInstance(for workflowIdentifier: WorkflowIdentifierEntity) async -> WorkflowInstance {
        let settings = await Settings()
        let results = await settings.cachedStatus
        let workflowInstance = results[workflowIdentifier.identifier]
        return workflowInstance ?? WorkflowInstance(id: workflowIdentifier.identifier)
    }

    func mostRecentCachedWorkflowInstance() async -> WorkflowInstance? {
        let settings = await Settings()
        let cachedStatus = await settings.cachedStatus
        return await settings.workflowsCache
            .map { id in
                cachedStatus[id] ?? WorkflowInstance(id: id)
            }
            .sortedByDateDescending()
            .first
    }

    func placeholder(in context: Context) -> SingleWorkflowTimelineEntry {
        return SingleWorkflowTimelineEntry(workflowInstance: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent,
                  in context: Context) async -> SingleWorkflowTimelineEntry {
        guard let workflowIdentifierEntity = configuration.workflow else {
            let workflowInstance = context.isPreview ? await mostRecentCachedWorkflowInstance() : nil
            return SingleWorkflowTimelineEntry(workflowInstance: workflowInstance)
        }
        let workflowInstance = await workflowInstance(for: workflowIdentifierEntity)
        return SingleWorkflowTimelineEntry(workflowInstance: workflowInstance)
    }

    func timeline(for configuration: ConfigurationAppIntent,
                  in context: Context) async -> Timeline<SingleWorkflowTimelineEntry> {
        guard let workflowIdentifierEntity = configuration.workflow else {
            return Timeline(entries: [SingleWorkflowTimelineEntry(workflowInstance: nil)], policy: .atEnd)
        }
        guard let workflowResult = try? await GitHubClient.default.fetch(id: workflowIdentifierEntity.identifier,
                                                                         options: [])
        else {
            return Timeline(entries: [placeholder(in: context)], policy: .standard)
        }
        let entry = SingleWorkflowTimelineEntry(workflowInstance: workflowResult)
        return Timeline(entries: [entry], policy: .standard)
    }

}
