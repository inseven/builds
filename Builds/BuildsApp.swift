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

import Diligence
import Interact

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
    var applicationModel: ApplicationModel!

    @AppStorage("authentication") var authentication: GitHub.Authentication?

    init() {
        applicationModel = ApplicationModel(settings: settings, authentication: $authentication)
    }

    var body: some Scene {

        // TODO: Make this a single window.
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print(url)
                    Task {
                        await applicationModel.client.authenticate(with: url)
                    }
                }
                .environmentObject(applicationModel)
                .handlesExternalEvents(preferring: ["x-builds-auth://oauth"], allowing: [])
        }
        .defaultSize(CGSize(width: 800, height: 720))
        .commands {
            ToolbarCommands()
        }

#if os(macOS)

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(applicationModel)
        }

        let title = "Builds Support (\(Bundle.main.version ?? "Unknown Version"))"

        About(repository: "inseven/builds", copyright: "Copyright © 2021-2024 Jason Morley") {
            Diligence.Action("GitHub", url: URL(string: "https://github.com/inseven/builds")!)
            Diligence.Action("Support", url: URL(address: "support@jbmorley.co.uk", subject: title)!)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
            }
            Acknowledgements("Thanks") {
                Credit("Lukas Fittl")
                Credit("Mike Rhodes")
                Credit("Sarah Barbour")
            }
        } licenses: {
            License("Builds", author: "Jason Morley", filename: "builds-license")
            License(Interact.Package.name, author: Interact.Package.author, url: Interact.Package.licenseURL)
            License("Material Icons", author: "Google", filename: "material-icons-license")
        }

#endif

    }
}
