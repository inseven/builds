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

struct ContentView: View {

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case add
        case settings
    }

    @State var sheet: SheetType?

    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject var applicationModel: ApplicationModel

    var body: some View {
        NavigationStack {
            VStack {
                if applicationModel.isAuthorized {
                    SummaryView()
                } else {
                    ContentUnavailableView {
                        Label("Logged Out", systemImage: "lock")
                    } description: {
                        Text("Sign in to view your GitHub Actions.")
                    } actions: {
                        Button {
                            applicationModel.authenticate()
                        } label: {
                            Text("Sign In")
                        }
                    }
                }
            }
            .navigationTitle("Builds")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {

#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        sheet = .settings
                    } label: {
                        Image(systemName: "gear")
                    }
                }
#endif

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        applicationModel.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }

            }
            .onAppear {
                applicationModel.refresh()
            }

        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .add:
                NavigationStack {
                    AddActionView(applicationModel: applicationModel)
                }
#if os(macOS)
                .frame(minWidth: 300, minHeight: 300)
#endif
            case .settings:
                NavigationView {
                    SettingsView()
                }
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            switch newValue {
            case .background:
                break
            case .inactive:
                break
            case .active:
                applicationModel.refresh()
            @unknown default:
                break
            }
        }
    }
}
