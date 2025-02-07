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

fileprivate struct MenuButtonStyleTintColorEnvironmentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}


extension EnvironmentValues {

    fileprivate var menuButtonStyleTintColor: Color? {
        get { self[MenuButtonStyleTintColorEnvironmentKey.self] }
        set { self[MenuButtonStyleTintColorEnvironmentKey.self] = newValue }
    }

}

extension View {

    func menuButtonStyleTintColor(_ tintColor: Color?) -> some View {
        return environment(\.menuButtonStyleTintColor, tintColor)
    }

}

struct MenuButtonStyle: ButtonStyle {

    struct LayoutMetrics {
        static let padding = 8.0
        static let cornerRadius = 8.0
    }

    @Environment(\.menuButtonStyleTintColor) private var tintColor

    @State var isActive: Bool = false

    func background() -> some View {
        if isActive {
            Color
                .accentColor
                .cornerRadius(LayoutMetrics.cornerRadius)
        } else {
            Color
                .clear
                .cornerRadius(LayoutMetrics.cornerRadius)
        }
    }

    var primaryColor: Color {
        if isActive {
            return Color.white
        } else {
            return Color.primary
        }
    }

    var secondaryColor: Color {
        if isActive {
            return Color.white
        } else {
            return Color.secondary
        }
    }

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        HStack {
            configuration.label
            Spacer()
        }
        .foregroundStyle(primaryColor, secondaryColor)
        .tint(isActive ? .white : tintColor)
        .padding(LayoutMetrics.padding)
        .background(background())
        .onHover { hovering in
            isActive = hovering
        }
    }

}

extension ButtonStyle where Self == MenuButtonStyle {

    static var menu: MenuButtonStyle {
        return MenuButtonStyle()
    }

}
