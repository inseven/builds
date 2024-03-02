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

@main
struct BuildsApp: App {

    var applicationModel: ApplicationModel!

    @MainActor init() {
        applicationModel = ApplicationModel()
    }

    var body: some Scene {

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

        SummaryWindow(applicationModel: applicationModel)

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(applicationModel)
        }

        About(Legal.contents)

#endif

    }
}
