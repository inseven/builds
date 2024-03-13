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

struct ToolbarButtonStyle: ButtonStyle {

    struct LayoutMetrics {
        static let padding = 8.0
        static let cornerRadius = 8.0
    }

    @State var isActive: Bool = false

    func background() -> some View {
        if isActive {
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

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        HStack {
            configuration.label
            Spacer()
        }
        .padding(LayoutMetrics.padding)
        .background(background())
        .onHover { hovering in
            isActive = hovering
        }
    }

}

extension ButtonStyle where Self == ToolbarButtonStyle {

    static var toolbar: ToolbarButtonStyle {
        return ToolbarButtonStyle()
    }

}
