//
//  WorkflowIdentifier.swift
//  BuildsWidgetExtension
//
//  Created by Jason Barrie Morley on 09/04/2024.
//

import AppIntents

struct WorkflowIdentifier: AppEntity {

    var id: String {
        return "\(repository):\(workflow):\(branch)"
    }

    let repository: String
    let workflow: Int
    let branch: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Workflow"
    static var defaultQuery = WorkflowQuery()

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(repository)",
                                     subtitle: "\(workflow) \(branch)")
    }

}
