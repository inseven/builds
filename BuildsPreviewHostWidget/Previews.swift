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

import BuildsCore

let timeline: [AllWorkflowsTimelineEntry] = [
    .init(summary: Summary()),
    .init(summary: Summary(operationState: .unknown, count: 12, date: .now)),
    .init(summary: Summary(operationState: .inProgress,
                           count: 12,
                           date: .now,
                           details: [
                            .inProgress: 4,
                            .success: 8
                           ])),
    .init(summary: Summary(operationState: .success,
                           count: 1,
                           date: .now,
                           details: [
                             .success: 1
                           ])),
    .init(summary: Summary(operationState: .skipped,
                           count: 12,
                           date: .now)),
    .init(summary: Summary(operationState: .failure,
                           count: 4,
                           date: .now.addingTimeInterval(-100),
                          details: [
                            .failure: 1,
                            .skipped: 1,
                            .success: 2
                          ])),
]

#Preview("All Workflows, System Small", as: .systemSmall) {
    AllWorkflowsWidget()
} timeline: {
    return timeline
}

#Preview("All Workflows, System Medium", as: .systemMedium) {
    AllWorkflowsWidget()
} timeline: {
    return timeline
}

#Preview("All Workflows, System Medium", as: .systemLarge) {
    AllWorkflowsWidget()
} timeline: {
    return timeline
}
