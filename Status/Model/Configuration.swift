//
//  Configuration.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

struct Configuration: Codable {

    public enum CodingKeys: String, CodingKey {
        case clientId = "client-id"
        case clientSecret = "client-secret"
    }

    let clientId: String
    let clientSecret: String

    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Self.self, from: data)
    }

}
