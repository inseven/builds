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

struct WorkflowInstanceCell: View {

    @Environment(\.isSelected) var isSelected
    @Environment(\.highlightState) var highlightState
    @Environment(\.selectionColor) var selectionColor

    struct LayoutMetrics {
        static let cornerRadius = 12.0
        static let popoverButtonSpacing = 10.0
        static let annotationListRowInsets = EdgeInsets(vertical: 8.0)
        static let worfklowJobListRowInsets = EdgeInsets(horizontal: -4.0, vertical: 2.0)
        static let selectionLineWidth = 3.0
        static let selectionPadding = 2.5
    }

    let workflowInstance: WorkflowInstance

    var showsHighlight: Bool {
        return isSelected || highlightState == .forSelection
    }

    var background: Color {
        if showsHighlight {
            return selectionColor
        } else {
            return Color.clear
        }
    }

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                HStack {
                    Text(workflowInstance.repositoryName)
                        .font(Font.headline)
                    Spacer()
                }
                HStack(spacing: LayoutMetrics.popoverButtonSpacing) {
                    if workflowInstance.annotations.count > 0 {
                        DetailsPopover(listRowInsets: LayoutMetrics.annotationListRowInsets) {
                            AnnotationList(workflowInstance: workflowInstance)
                        } label: {
                            Image(systemName: "text.alignleft")
                        }
                    }
                    DetailsPopover(listRowInsets: LayoutMetrics.worfklowJobListRowInsets) {
                        WorkflowJobList(jobs: workflowInstance.jobs)
                            .buttonStyle(.menu)
                    } label: {
                        StatusImage(operationState: workflowInstance.operationState)
                            .help(workflowInstance.operationState.name)
                    }
                    .disabled(workflowInstance.jobs.isEmpty)
                }

            }
            GridRow {
                HStack {
                    Text(workflowInstance.workflowName)
                    Text(workflowInstance.id.branch)
                        .monospaced()
                    Text(workflowInstance.shortSha ?? "-")
                        .monospaced()
                }
                VStack {
                    if let createdAt = workflowInstance.createdAt {
                        TimelineView(.periodic(from: createdAt, by: 1)) { _ in
                            Text(createdAt, format: .relative(presentation: .numeric))
                        }
                    } else {
                        Text("never")
                    }
                }
                .gridColumnAlignment(.trailing)
            }
            .font(.subheadline)
            .opacity(0.6)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding()
        .background(workflowInstance.statusColor)
        .foregroundColor(.black)
        .clipShape(RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius))
#if os(iOS)
        .contentShape([.contextMenuPreview, .dragPreview, .hoverEffect], 
                      RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius))
        .hoverEffect(.automatic)
#endif
        .padding(LayoutMetrics.selectionPadding)
        .overlay(RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius + LayoutMetrics.selectionPadding)
            .stroke(background, lineWidth: LayoutMetrics.selectionLineWidth))
        .padding(-LayoutMetrics.selectionPadding)
    }

}
