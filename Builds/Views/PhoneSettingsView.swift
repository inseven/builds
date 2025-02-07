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

#if os(iOS)

struct PhoneSettingsView: View {

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case managePermissions

    }

    @EnvironmentObject var applicationModel: ApplicationModel
    @Environment(SceneModel.self) var sceneModel

    @Environment(\.dismiss) var dismiss

    @State var sheet: SheetType? = nil

    var body: some View {

        @Bindable var sceneModel = sceneModel

        Form {

            Section {
                Toggle("Use In-App Browser", isOn: $applicationModel.useInAppBrowser)
            } header: {
                Text("Viewing")
            }

            Section {
                AboutButton(Legal.contents)
            }

            Section {

                Button {
#if os(macOS)
                    applicationModel.managePermissions()
#else
                    sheet = .managePermissions
#endif
                } label: {
                    Text("Manage GitHub Permissions")
                }
                .disabled(!applicationModel.isSignedIn)

            }

            Section {

                Button {
                    sceneModel.signOut()
                } label: {
                    Text("Sign Out")
                }
                .disabled(!applicationModel.isSignedIn)

            }

        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .presents(confirmable: $sceneModel.confirmation)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .managePermissions:
                SafariWebView(url: applicationModel.permissionsURL)
            }
        }
        .dismissable()
    }

}

#endif
