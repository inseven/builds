//
//  Settings.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

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
