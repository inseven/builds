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

import WidgetKit

import Interact

struct AllWorkflowsTimelineProvider: TimelineProvider {

    // This fetches the cached version.
    var summary: Summary {
        get async {
            let settings = await Settings()
            let summary = await settings.summary ?? Summary()
            return summary
        }
    }

    // This fetches a live version.
    func fetchSummary() async throws -> Summary {
        let settings = await Settings()
        let workflows = await settings.workflowsCache
        let workflowInstances = try await GitHubClient.default.update(workflows: workflows, options: [])
        return Summary(workflowInstances: workflowInstances)
    }

    func placeholder(in context: Context) -> AllWorkflowsTimelineEntry {
        return AllWorkflowsTimelineEntry(summary: Summary())
    }

    func getSnapshot(in context: Context, completion: @escaping (AllWorkflowsTimelineEntry) -> Void) {
        Task {
            completion(AllWorkflowsTimelineEntry(summary: await summary))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AllWorkflowsTimelineEntry>) -> Void) {
        Task {
            do {
                let summary = try await fetchSummary()
                completion(Timeline(entries: [AllWorkflowsTimelineEntry(summary: summary)], policy: .standard))
            } catch {
                print("Failed to fetch all results with error \(error)")
                completion(Timeline(entries: [AllWorkflowsTimelineEntry(summary: Summary())], policy: .standard))
            }
        }
    }

}
