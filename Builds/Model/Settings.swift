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

import Foundation

import Interact

class Settings: ObservableObject {

    private enum Key: String {
        case items = "Items"
    }

    @MainActor @Published var actions: [Action] = [] {
        didSet {
            do {
                try defaults.set(codable: actions, forKey: .items)
            } catch {
                print("Failed to save state with error \(error).")
            }
        }
    }

    private let defaults: KeyedDefaults<Key>

    @MainActor init() {
        defaults = KeyedDefaults()
        actions = (try? defaults.codable(forKey: .items, default: [Action]())) ?? []
    }

    @MainActor func addAction(_ action: Action) {
        actions.append(action)
    }

    @MainActor func removeAction(_ action: Action) {
        actions.removeAll { $0.id == action.id }
    }

}
