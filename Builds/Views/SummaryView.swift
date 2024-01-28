//
//  SummaryView.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import SwiftUI

struct SummaryView: View {

    @EnvironmentObject var manager: Manager

    @Environment(\.openURL) var openURL

    private var layout = [GridItem(.flexible())]

    var body: some View {
        // TODO: Maybe not a grid?
        ScrollView {
            LazyVGrid(columns: layout) {
                ForEach(manager.status) { status in
                    SummaryCell(status: status)
                        .contextMenu {
                            Button(role: .destructive) {
                                manager.removeAction(status.action)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        // TODO: Is there a better interaction model for this? Maybe it should be a selectable list?
                        .onTapGesture {
                            guard let workflowRun = status.workflowRun else {
                                return
                            }
                            openURL(workflowRun.htmlURL)
                        }

                }
            }
            .padding()
        }
    }

}
