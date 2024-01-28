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

// TODO: MainActor?
class Settings: ObservableObject {

    private enum Key: String {
        case items = "Items"
    }

    private let defaults: UserDefaults
    private var _actions: [Action] = []

    init() {
        defaults = UserDefaults.standard
        _actions = self.codable(for: .items, defaultValue: [])
    }

    private func string(for key: Key) -> String? {
        return defaults.string(forKey: key.rawValue)
    }

    private func codable<T: Codable>(for key: Key) -> T? {
        guard let value = string(for: key),
              let data = value.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func codable<T: Codable>(for key: Key, defaultValue: T) -> T {
        guard let value: T = codable(for: key) else {
            return defaultValue
        }
        return value
    }

    private func set(_ value: String, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    // TODO: Throw?
    private func set<T: Codable>(_ value: T, for key: Key) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(value)
        let string = String(data: data, encoding: .utf8)!
        print(string)
        set(string, for: .items)
    }

    // TODO: Private?
    var actions: [Action] {
        dispatchPrecondition(condition: .onQueue(.main))
        return _actions
    }

    func addAction(_ action: Action) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.objectWillChange.send()
        _actions.append(action)
        set(_actions, for: .items)
    }

    func removeAction(_ action: Action) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.objectWillChange.send()
        _actions.removeAll { $0.id == action.id }
        set(_actions, for: .items)
    }

}
