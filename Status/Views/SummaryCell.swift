//
//  SummaryCell.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import SwiftUI

struct SummaryCell: View {

    let status: ActionStatus

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(status.action.repositoryName)
                    .font(Font.headline)
                Text(status.name)
                    .font(Font.subheadline)
                    .opacity(0.6)
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let conclusion = status.workflowRun?.conclusion {
                    switch conclusion {
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                    case .failure:
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                Text(status.lastRun)
                    .font(Font.subheadline)
                    .opacity(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(status.statusColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

}
