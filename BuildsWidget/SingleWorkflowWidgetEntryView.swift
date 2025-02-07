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
import SwiftUI

import BuildsCore

struct SingleWorkflowWidgetEntryView : View {

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var entry: SingleWorkflowTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            if let workflowInstance = entry.workflowInstance {
                HStack {
                    Spacer()
                    Image(systemName: workflowInstance.systemImage)
                        .imageScale(.large)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(workflowInstance.repositoryName)
                    VStack(alignment: .leading) {
                        Text(workflowInstance.workflowName)
                        Text(workflowInstance.id.branch)
                            .monospaced()
                    }
                    .font(.footnote)
                    .opacity(0.6)
                }
            } else {
                Text("Edit widget to select workflow")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
            }
        }
        .foregroundColor(widgetRenderingMode == .fullColor ? .black : nil)
        .containerBackground(entry.workflowInstance?.statusColor ?? .gray, for: .widget)
    }
}
