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

struct StatusButton: View {

    @Environment(\.presentURL) var presentURL

    @ObservedObject var applicationModel: ApplicationModel

    @State var error: Error?

    var sceneModel: SceneModel

    var body: some View {
            Button {
                self.error = applicationModel.lastError
            } label: {
                HStack {
                    if applicationModel.lastError != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(minWidth: 21.0)
            }
            .disabled(applicationModel.lastUpdate == nil)
            .confirmationDialog("Refresh Error", isPresented: $error.bool()) {
                if let error {

                    if error.isAuthenticationFailure {

                        Button {
                            applicationModel.logIn()
                        } label: {
                            Text("Sign In")
                        }

                    } else {

                        Button {
                            await applicationModel.refresh()
                        } label: {
                            Text("Refresh")
                        }

                        Button {
                            presentURL(URL(string: "https://www.githubstatus.com")!)
                        } label: {
                            Text("Check GitHub Status")
                        }

                        Button(role: .destructive) {

                        } label: {
                            Text("Cancel")
                        }

                    }

                }

            } message: {
                Text(error?.recoveryMessage ?? "")
            }
    }

}

extension Error {

    var isAuthenticationFailure: Bool {
        if let error = self as? BuildsError {
            if case .authenticationFailure = error {
                return true
            }
        } else if let error = self as? HTTPURLResponseError {
            if case .httpError(.unauthorized) = error {
                return true
            }
        }
        return false
    }

    var recoveryMessage: String {
        var lines: [String] = []
        lines.append("\"\(self.localizedDescription)\"")

        if !isAuthenticationFailure {
            lines.append("GitHub sometimes encounters incidents which can lead to transient failures. You can check 'GitHub Status' or select 'Refresh' to try again.")
        }

        return lines.joined(separator: "\n\n")
    }

}
