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
struct StatusApp: App {

    let settings = Settings()

    @AppStorage("authentication") var authentication: GitHub.Authentication?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Manager(settings: settings, authentication: $authentication))
        }
    }
}
