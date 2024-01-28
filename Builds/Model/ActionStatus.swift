//
//  ActionStatus.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import SwiftUI

struct ActionStatus: Identifiable {

    var id: Action { action }

    var action: Action
    // TODO: Rename this to latestRun
    var workflowRun: GitHub.WorkflowRun?

}

extension ActionStatus {

    var name: String {
        let name = "\(workflowRun?.name ?? String(action.workflowId))"
        guard let branch = action.branch else {
            return name
        }
        return "\(name) (\(branch))"
    }

    var statusColor: Color {
        guard let workflowRun = workflowRun else {
            return .gray
        }
        if workflowRun.status == .inProgress {
            return .orange
        }
        guard let conclusion = workflowRun.conclusion else {
            return .gray
        }
        switch conclusion {
        case .success:
            return .green
        case .failure:
            return .red
        }
    }

    var lastRun: String {
        guard let createdAt = workflowRun?.createdAt else {
            return "Never"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

}
