//
//  ActionStatus.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

struct ActionStatus: Identifiable {

    var id: Action { action }

    var action: Action
    // TODO: Rename this to latestRun
    var workflowRun: GitHub.WorkflowRun?

}
