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

import BuildsCore

struct AnnotationList: View {

    struct LayoutMetrics {
        static let interItemSpacing = 8.0
    }

    let result: WorkflowResult

    var body: some View {
        let annotations = result.annotations
        ForEach(annotations) { annotation in
            HStack(alignment: .firstTextBaseline) {
                switch annotation.annotation.annotation_level {
                case .failure:
                    Image(systemName: "exclamationmark.octagon.fill")
                        .symbolRenderingMode(.multicolor)
                case .warning:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                }
                VStack(alignment: .leading, spacing: LayoutMetrics.interItemSpacing) {
                    if let job = result.job(for: annotation) {
                        Text(job.name)
                            .fontWeight(.bold)
                    }
                    if !annotation.annotation.title.isEmpty {
                        Text(annotation.annotation.title)
                    }
                    Text(annotation.annotation.message)
                        .lineLimit(10)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
            }
        }
    }

}
