//
//  Action.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

struct Action: Identifiable, Hashable, Codable {

    let id: UUID
    let repositoryName: String
    let workflowId: Int
    let branch: String?

    init(repositoryName: String, workflowId: Int, branch: String?) {
        self.id = UUID()
        self.repositoryName = repositoryName
        self.workflowId = workflowId
        self.branch = branch
    }

}
