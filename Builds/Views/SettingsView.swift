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

struct SettingsView: View {

    @EnvironmentObject var applicationModel: ApplicationModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {

#if os(iOS)
            Section {
                AboutButton(Legal.contents)
            }
#endif

            Section {

                Button {
                    applicationModel.managePermissions()
                } label: {
                    Text("Manage GitHub Permissions")
                }
                .disabled(!applicationModel.isAuthorized)

            }

            Section {

                Button {
                    applicationModel.logOut()
                } label: {
                    Text("Log Out")
                }
                .disabled(!applicationModel.isAuthorized)

            }

        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(/* placement: .navigationBarTrailing */) {
                Button("Done") {
                    dismiss()
                }
            }
#endif
        }
    }

}
