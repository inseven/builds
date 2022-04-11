//
//  SummaryView.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import SwiftUI

struct SummaryView: View {

    @EnvironmentObject var manager: Manager

    private var layout = [GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: layout) {
                ForEach(manager.status) { status in
                    SummaryCell(status: status)
                        .contextMenu {
                            Button {

                            } label: {
                                Label("Run Workflow", systemImage: "play")
                            }
                            Divider()
                            Button(role: .destructive) {
                                manager.removeAction(status.action)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                    }
                }
            }
            .padding()
        }
    }

}
