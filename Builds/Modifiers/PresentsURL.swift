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

#if os(iOS)

import SwiftUI

fileprivate struct URLPresenter<Content: View>: View {

    @Binding var url: URL?
    @Binding var isActive: Bool

    let content: Content

    init(url: Binding<URL?>, isActive: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._url = url
        self._isActive = isActive
        self.content = content()
    }

    var binding: Binding<URL?> {
        return .init {
            guard isActive else {
                return nil
            }
            return url
        } set: { newValue in
            guard isActive else {
                return
            }
            url = newValue
        }
    }

    var body: some View {
        content
            .sheet(item: binding) { url in
                SafariWebView(url: url)
                    .ignoresSafeArea()
            }
    }

}

extension View {

    func showsURL(_ url: Binding<URL?>, isActive: Bool = true) -> some View {
        SheetReader("url") { isTop in
            URLPresenter(url: url, isActive: isTop) {
                self
            }
        }
    }

}

#endif
