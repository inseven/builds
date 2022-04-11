//
//  Settings.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

class Settings: ObservableObject {

    let defaults: UserDefaults
    var _actions: [Action] = []

    init() {
        defaults = UserDefaults.standard
    }

    var actions: [Action] {
        return _actions
    }

    func addAction(_ action: Action) {
        self.objectWillChange.send()
        _actions.append(action)
    }

    func removeAction(_ action: Action) {
        self.objectWillChange.send()
        _actions.removeAll { $0.id == action.id }
    }

}
