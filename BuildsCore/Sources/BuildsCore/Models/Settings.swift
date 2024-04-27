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

import Interact

public class Settings {

    private enum Key: String {
        case accessToken
        case favorites
        case lastUpdate
        case sceneSettings
        case status
        case summary
        case useInAppBrowser
        case workflowsCache
    }

    @MainActor private let defaults = KeyedDefaults<Key>(defaults: UserDefaults(suiteName: "group.uk.co.jbmorley.builds")!)
    @MainActor private let keychain = KeychainManager<Key>(accessGroup: .sharedKeychainAccessGroup)

    @MainActor public var accessToken: String? {
        get {
            return try? keychain.string(forKey: .accessToken)
        }
        set {
            try? keychain.set(newValue, forKey: .accessToken, accessPolicy: .afterFirstUnlock)
        }
    }

    @MainActor public var workflows: [WorkflowInstance.ID] {
        get {
            NSUbiquitousKeyValueStore.default.synchronize()
            guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Key.favorites.rawValue) else {
                return []
            }
            do {
                return try JSONDecoder().decode([WorkflowInstance.ID].self, from: data)
            } catch {
                print("Failed to load workflows with error \(error).")
            }
            return []
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                let store = NSUbiquitousKeyValueStore.default
                guard store.data(forKey: Key.favorites.rawValue) != data else {
                    return
                }
                store.set(data, forKey: Key.favorites.rawValue)
                store.synchronize()
            } catch {
                print("Failed to save workflows with error \(error).")
            }
        }
    }

    @MainActor public var workflowsCache: [WorkflowInstance.ID] {
        get {
            do {
                return try defaults.codable(forKey: .workflowsCache, default: [])
            } catch {
                print("Failed to load cached workflows with error \(error).")
                return []
            }
        }
        set {
            do {
                try defaults.set(codable: newValue, forKey: .workflowsCache)
            } catch {
                print("Failed to cache workflows with error \(error).")
            }
        }
    }

    @MainActor public var lastUpdate: Date? {
        get {
            return defaults.object(forKey: .lastUpdate) as? Date
        }
        set {
            defaults.set(newValue, forKey: .lastUpdate)
        }
    }

    @MainActor public var sceneSettings: SceneSettings {
        didSet {
            try? defaults.set(codable: sceneSettings, forKey: .sceneSettings)
        }
    }

    @MainActor public var cachedStatus: [WorkflowInstance.ID: WorkflowInstance] {
        get {
            return (try? defaults.codable(forKey: .status)) ?? [:]
        }
        set {
            do {
                try defaults.set(codable: newValue, forKey: .status)
            } catch {
                print("Failed to save status with error \(error).")
            }
        }
    }

    @MainActor public var summary: Summary? {
        get {
            return (try? defaults.codable(forKey: .summary))
        }
        set {
            do {
                try defaults.set(codable: newValue, forKey: .summary)
            } catch {
                print("Failed to save summary with error \(error).")
            }
        }
    }

    @MainActor public var useInAppBrowser: Bool {
        get {
            return defaults.bool(forKey: .useInAppBrowser, default: true)
        }
        set {
            defaults.set(newValue, forKey: .useInAppBrowser)
        }
    }

    @MainActor public init() {
        // We read and cache some of the settings here to ensure we're not hitting user defaults when creating SwiftUI
        // models that shadow these values themselves.
        sceneSettings = (try? defaults.codable(forKey: .sceneSettings)) ?? SceneSettings()
    }

}
