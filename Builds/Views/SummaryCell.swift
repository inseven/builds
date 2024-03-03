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

extension GitHub.Annotation: Identifiable {

    var id: String {
        return "\(path):\(start_line):\(end_line):\(start_column ?? -1):\(end_column ?? -1)"
    }

}

struct SummaryCell: View {

    @State var isPresented: Bool = false

    let status: WorkflowSummary

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                HStack {
                    Text(status.action.repositoryName)
                        .font(Font.headline)
                    Spacer()
                }
                HStack {
                    if status.annotations.count > 0 {
                        Button {
                            isPresented = true
                            print("Annotations = \(status.annotations)")
                        } label: {
                            Image(systemName: "text.alignleft")
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                            VStack(alignment: .leading) {
                                ForEach(status.annotations) { annotation in
                                    HStack(alignment: .firstTextBaseline) {
                                        if annotation.annotation_level == "warning" {
                                            Image(systemName: "exclamationmark.triangle")
                                        }
                                        VStack(alignment: .leading) {
                                            Text("Unknown Job")
                                                .fontWeight(.bold)
                                            Text(annotation.message)
                                                .lineLimit(10)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: 300)
                            .foregroundColor(.primary)
                        }
                    }
                    if let workflowRun = status.workflowRun {
                        switch workflowRun.status {
                        case .queued:
                            Image(systemName: "clock.arrow.circlepath")
                        case .waiting:
                            Image(systemName: "clock")
                        case .inProgress:
                            ProgressView()
                                .controlSize(.small)
                                .padding(.leading, 4)
                        case .completed:
                            switch workflowRun.conclusion {
                            case .success:
                                Image(systemName: "checkmark")
                            case .failure:
                                Image(systemName: "xmark")
                            case .cancelled:
                                Image(systemName: "exclamationmark.octagon")
                            case .none:
                                Image(systemName: "questionmark")
                            }
                        }
                    }
                }

            }
            GridRow {
                Text(status.details)
                    .font(Font.subheadline)
                    .opacity(0.6)
                TimelineView(.periodic(from: Date(), by: 1)) { _ in
                    Text(status.lastRun)
                        .font(Font.subheadline)
                        .opacity(0.6)
                }
                .gridColumnAlignment(.trailing)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding()
        .background(status.statusColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundColor(.black)
    }

}
