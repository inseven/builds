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

struct MainContentView: View {

    @ObservedObject var applicationModel: ApplicationModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    @StateObject var sceneModel: SceneModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _sceneModel = StateObject(wrappedValue: SceneModel(applicationModel: applicationModel))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $sceneModel.columnVisibility) {
            Sidebar(applicationModel: applicationModel, sceneModel: sceneModel)
                .toolbar {
#if os(iOS)
                    ToolbarItem(id: "settings", placement: .topBarLeading) {
                        Button {
                            sceneModel.showSettings()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
#endif
                }
        } detail: {
            VStack {
                if let section = sceneModel.section {
                    WorkflowsSection(applicationModel: applicationModel, sceneModel: sceneModel, section: section)
                        .id(section)
                } else {
                    ContentUnavailableView {
                        Label("Nothing Selected", systemImage: "sidebar.leading")
                    } description: {
                        Text("Select a section from the sidebar to view workflows.")
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .navigationTitle(sceneModel.section?.title ?? "")
            .toolbar(id: "main") {
                ToolbarItem(id: "manage-workflows", placement: .primaryAction) {
                    Button {
                        sceneModel.manageWorkflows()
                    } label: {
                        Label("Manage Workflows", systemImage: "checklist")
                    }
                    .help("Select workflows to display")
                    .disabled(!applicationModel.isAuthorized)
                }
            }
        }
        .presents(confirmable: $sceneModel.confirmation)
#if os(iOS)
        // iOS relies on sheets, but macOS uses windows so doesn't need this.
        .sheet(item: $sceneModel.sheet) { sheet in
            switch sheet {
            case .add:
                NavigationStack {
                    WorkflowsContentView(applicationModel: applicationModel)
                }
            case .settings:
                NavigationView {
                    PhoneSettingsView()
                        .environmentObject(sceneModel)
                }
            case .logIn:
                SafariWebView(url: applicationModel.client.authorizationURL)
                    .ignoresSafeArea()
            case .view(let id):
                NavigationStack {
                    WorkflowInspector(applicationModel: applicationModel, id: id)
                }
            }
        }
        .showsURL($sceneModel.previewURL)
#endif
        .runs(sceneModel)
        .requestsHigherFrequencyUpdates()
        .environmentObject(sceneModel)
#if os(iOS)
        .presenter(sceneModel)
#endif
        .focusedSceneObject(sceneModel)
        .onChange(of: scenePhase) { oldValue, newValue in
            switch newValue {
            case .background:
                break
            case .inactive:
                break
            case .active:
                Task {
                    await applicationModel.refresh()
                }
            @unknown default:
                break
            }
        }
    }
}
