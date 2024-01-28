//
//  StatusApp.swift
//  Status
//
//  Created by Jason Barrie Morley on 31/03/2022.
//

import SwiftUI

extension GitHub.Authentication: RawRepresentable {

    public init?(rawValue: String) {
        guard !rawValue.isEmpty else {
            return nil
        }
        self.accessToken = rawValue
    }

    public var rawValue: String {
        return accessToken
    }

}

@main
struct BuildsApp: App {

    let settings = Settings()
    var manager: Manager!

    @AppStorage("authentication") var authentication: GitHub.Authentication?

    init() {
        manager = Manager(settings: settings, authentication: $authentication)
    }

    var body: some Scene {

        // TODO: Make this a single window.
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print(url)
                    Task {
                        await manager.client.authenticate(with: url)
                    }
                }
                .environmentObject(manager)
                .handlesExternalEvents(preferring: ["x-builds-auth://oauth"], allowing: [])
        }

#if os(macOS)

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(manager)
        }

#endif

    }
}
