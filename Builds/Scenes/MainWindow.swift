// Copyright (c) 2021-2025 Jason Morley
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

struct MainWindow: Scene {

    static let id = "main"

    @EnvironmentObject var applicationModel: ApplicationModel
    @State var error: Error? = nil

    var body: some Scene {
        SingleWindow("Builds", id: Self.id) {
            MainContentView(applicationModel: applicationModel)
                .handlesAuthentication()
                .handlesExternalEvents(preferring: [], allowing: [.main])
                .environmentObject(applicationModel)
        }
        .defaultSize(CGSize(width: 800, height: 720))
        .commands {
            SidebarCommands()
            ToolbarCommands()
        }
        .handlesExternalEvents(matching: [.main, .auth])
    }

}
