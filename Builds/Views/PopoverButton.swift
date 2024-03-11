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

fileprivate struct LayoutMetrics {
    static let cornerRadius = 4.0
    static let padding = 2.0
    static let backgroundPadding = 4.0
}


struct PopoverButton<Label: View>: View {

    @State var isActive: Bool = false

    let isShowingPopover: Bool
    let action: () -> Void
    let label: Label

    init(isShowingPopover: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isShowingPopover = isShowingPopover
        self.action = action
        self.label = label()
    }

    func background() -> some View {
        if isActive || isShowingPopover {
            Color
                .black
                .opacity(0.1)
                .cornerRadius(LayoutMetrics.cornerRadius)
        } else {
            Color
                .clear
                .cornerRadius(LayoutMetrics.cornerRadius)
        }
    }

    var body: some View {
        label
            .padding(LayoutMetrics.padding + LayoutMetrics.backgroundPadding)
            .background(background())
            .onHover { hovering in
                isActive = hovering
            }
            .onTapGesture {
                guard !isShowingPopover else {
                    return
                }
                action()
            }
            .padding(-1 * LayoutMetrics.backgroundPadding)
    }

}
