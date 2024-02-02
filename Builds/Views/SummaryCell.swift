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

struct SummaryCell: View {

    let status: ActionStatus

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                HStack {
                    Text(status.action.repositoryName)
                        .font(Font.headline)
                    Spacer()
                }
                if let workflowRun = status.workflowRun {
                    switch workflowRun.status {
                    case .waiting:
                        Image(systemName: "clock")
                    case .inProgress:
                        Image(systemName: "play")
                    case .completed:
                        switch workflowRun.conclusion {
                        case .success:
                            Image(systemName: "checkmark")
                        case .failure:
                            Image(systemName: "xmark")
                        case .none:
                            Image(systemName: "questionmark")
                        }
                    }
                }

            }
            GridRow {
                Text(status.name)
                    .font(Font.subheadline)
                    .opacity(0.6)
                Text(status.lastRun)
                    .font(Font.subheadline)
                    .opacity(0.6)
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
