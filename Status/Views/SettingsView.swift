//
//  SettingsView.swift
//  Status
//
//  Created by Jason Barrie Morley on 10/04/2022.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var manager: Manager

    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section("Account") {

                Button {
                    manager.client.logOut()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Log Out")
                }

                Button {
                    openURL(manager.client.permissionsURL)
                } label: {
                    Text("Manage Permissions")
                }
                
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
                    presentationMode.wrappedValue.dismiss()
                }
            }
#endif
        }
    }

}
