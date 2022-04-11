//
//  Action.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

struct Action: Identifiable, Hashable {

    let id: UUID = UUID()
    let repositoryName: String
    let workflowId: Int
    let branch: String?

}
