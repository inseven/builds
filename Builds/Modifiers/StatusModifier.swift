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

struct StatusModifier<Label: View>: ViewModifier {

    var label: Label

    init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    func body(content: Content) -> some View {
#if os(macOS)
        content
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 0) {
                        label
                    }
                    .padding(8)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
                .font(.footnote)
                .background(.ultraThickMaterial)
            }
#else
        content
            .toolbar {
                ToolbarItem(placement: .status) {
                    HStack(spacing: 0) {
                        label
                    }
                    .font(.footnote)
                }
            }

#endif
    }

}

extension View {

    func status<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        return modifier(StatusModifier(label: label))
    }

}
