//
//  SettingsView.swift
//  Status
//
//  Created by Jason Barrie Morley on 10/04/2022.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var manager: Manager

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Button {
                manager.client.logOut()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Log Out")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

}
