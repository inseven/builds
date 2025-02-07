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

import SwiftUI

import BuildsCore

struct AnnotationList: View {

    struct LayoutMetrics {
        static let interItemSpacing = 8.0
    }

    let workflowInstance: WorkflowInstance

    var body: some View {
        ForEach(workflowInstance.annotations) { annotation in
            Label {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: LayoutMetrics.interItemSpacing) {
                        if let job = workflowInstance.job(for: annotation) {
                            Text(job.name)
                                .fontWeight(.bold)
                        }
                        if !annotation.title.isEmpty {
                            Text(annotation.title)
                        }
                        Text(annotation.message)
                            .lineLimit(10)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                }
            } icon: {
                switch annotation.level {
                case .failure:
                    Image(systemName: "exclamationmark.octagon")
                        .symbolRenderingMode(.multicolor)
                case .warning:
                    Image(systemName: "exclamationmark.triangle")
                        .symbolRenderingMode(.multicolor)
                case .notice:
                    Image(systemName: "info.circle")
                        .symbolRenderingMode(.multicolor)
                }
            }
        }
    }

}
