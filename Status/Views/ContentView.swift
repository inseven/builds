//
//  ContentView.swift
//  Status
//
//  Created by Jason Barrie Morley on 31/03/2022.
//

import SwiftUI

struct ContentView: View {

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case authenticate
        case add
        case settings
    }

    @State var sheet: SheetType?

    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject var manager: Manager

    var body: some View {
        NavigationStack {
            VStack {
                switch manager.client.state {
                case .authorized:
                    SummaryView()
                case .unauthorized:
                    Button {
#if os(iOS)
                        sheet = .authenticate
#else
                        openURL(manager.client.authorizationUrl())
#endif
                    } label: {
                        Text("Authenticate")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Actions")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {

#if os(iOS)
                ToolbarItem(placement: .secondaryAction) {
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

            }
            .onAppear {
                manager.refresh()
            }

        }
        .sheet(item: $sheet, content: { sheet in
            switch sheet {
            case .authenticate:
                AuthenticationView(client: manager.client) { result in
                    dispatchPrecondition(condition: .onQueue(.main))
                    switch result {
                    case .success:
                        print("AUTHENTICATED!")
                    case .failure(let error):
                        print("FAILED WITH ERROR \(error)")
                    }
                    self.sheet = nil
                }
            case .add:
                NavigationStack {
                    ActionWizard()
                }
#if os(macOS)
                .frame(minWidth: 300, minHeight: 300)
#endif
            case .settings:
                NavigationView {
                    SettingsView()
                }
            }
        })
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                manager.refresh()
            @unknown default:
                break
            }
        }
    }
}
