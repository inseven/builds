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

struct WorkflowJobList: View {

    struct LayoutMetrics {
        static let statusImageSize = CGSize(width: 8.0, height: 8.0)
        static let statusImagePadding = 4.0
    }

    @Environment(\.presentURL) private var presentURL

    let jobs: [GitHub.WorkflowJob]

    private func color(for workflowJob: GitHub.WorkflowJob) -> Color {
        return SummaryState(status: workflowJob.status, conclusion: workflowJob.conclusion).color
    }

    var body: some View {
        ForEach(jobs) { job in
            Button {
                presentURL(job.html_url)
            } label: {
                HStack {
                    StatusImage(status: job.status, conclusion: job.conclusion, size: LayoutMetrics.statusImageSize)
                        .foregroundStyle(.white)
                        .fontWeight(.heavy)
                        .padding(LayoutMetrics.statusImagePadding)
                        .background(Circle()
                            .fill(color(for: job)))
                    Text(job.name)
                    Spacer()
                    if let startDate = job.started_at {
                        DurationView(startDate: startDate, endDate: job.completed_at)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
