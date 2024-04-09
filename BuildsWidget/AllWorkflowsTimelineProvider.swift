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

struct AllWorkflowsTimelineProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (AllWorkflowsEntry) -> Void) {
        // TODO:
        completion(AllWorkflowsEntry(summary: summary))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AllWorkflowsEntry>) -> Void) {
        // TODO: Reload policy.
        completion(Timeline(entries: [AllWorkflowsEntry(summary: summary)], policy: .after(.now + 60)))
    }

    enum Key: String {
        case summary
    }

    var summary: Summary {
        return (try? defaults.codable(forKey: .summary)) ?? Summary()
    }

    // TODO: Settings
    let defaults = KeyedDefaults<Key>(defaults: UserDefaults(suiteName: "group.uk.co.jbmorley.builds")!)

    init() {
    }

    // TODO: UNUSED?
    func placeholder(in context: Context) -> AllWorkflowsEntry {
        return AllWorkflowsEntry()
    }

//    func snapshot(in context: Context) async -> AllWorkflowsEntry {
//        return AllWorkflowsEntry(summary: summary)
//    }
//
//    func timeline(in context: Context) async -> Timeline<AllWorkflowsEntry> {
//        let entry = AllWorkflowsEntry(summary: summary)
//        return Timeline(entries: [entry], policy: .atEnd)
//    }

}
