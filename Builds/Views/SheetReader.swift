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

fileprivate class ViewStack {

    var stacks: [String:[UUID]] = [:]

    func push(context: String, id: UUID) {
        var stack = stacks[context] ?? []
        stack.append(id)
        stacks[context] = stack
    }

    func pop(context: String) {
        _ = stacks[context]?.popLast()
    }

    func isTop(context: String, id: UUID) -> Bool {
        return stacks[context]?.last == id
    }

}

private struct ViewStackEnvironmentKey: EnvironmentKey {
    static let defaultValue = ViewStack()
}


extension EnvironmentValues {

    fileprivate var viewStack: ViewStack {
        get { self[ViewStackEnvironmentKey.self] }
        set { self[ViewStackEnvironmentKey.self] = newValue }
    }

}

struct SheetReader<Content: View>: View {

    @Environment(\.viewStack) fileprivate var viewStack

    @State var id = UUID()

    let context: String
    let content: (Binding<Bool>) -> Content

    init(_ context: String, @ViewBuilder content: @escaping (Binding<Bool>) -> Content) {
        self.context = context
        self.content = content
    }

    var isTop: Binding<Bool> {
        return Binding {
            return viewStack.isTop(context: context, id: id)
        } set: { _ in }
    }

    var body: some View {
        content(isTop)
            .onAppear {
                viewStack.push(context: context, id: id)
            }
            .onDisappear {
                viewStack.pop(context: context)
            }
    }

}
