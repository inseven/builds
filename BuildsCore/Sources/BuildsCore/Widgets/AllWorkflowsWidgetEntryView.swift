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

extension OperationState: Identifiable {

    public var id: Self {
        return self
    }

}

struct AllWorkflowsWidgetEntryView : View {

    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var entry: AllWorkflowsTimelineProvider.Entry

    var maximumDetailCount: Int {
        switch widgetFamily {
        case .systemSmall:
            return 0
        case .systemMedium:
            return 2
        case .systemLarge:
            return 20
        default:
            return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(systemName: entry.summary.operationState.systemImage)
                    .imageScale(.large)
                    .redacted(reason: entry.summary.count > 0 ? nil : .placeholder)
            }
            Spacer()
            let format = NSLocalizedString("PLURAL_WORKFLOW_LABEL", bundle: .module, comment: "Pluralised widget workflow label")
            let label = String.localizedStringWithFormat(format, entry.summary.count)
            if maximumDetailCount > 0 {
                Grid {
                    GridRow {
                        Text(entry.summary.count, format: .number)
                            .gridColumnAlignment(.trailing)
                        Text(label)
                            .gridColumnAlignment(.leading)
                    }
                    ForEach(Array(entry.summary.details.keys.sorted().prefix(maximumDetailCount))) { key in
                        GridRow {
                            Text(entry.summary.details[key]!, format: .number)
                            Text(key.name)
                        }
                    }
                    .opacity(0.6)
                }
            } else {
                Text("\(entry.summary.count) \(label)", bundle: .module)
            }
        }
        .foregroundColor(widgetRenderingMode == .fullColor ? .black : nil)
        .containerBackground(entry.summary.operationState.color, for: .widget)
    }
}
