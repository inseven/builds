//
//  URL.swift
//  Status
//
//  Created by Jason Barrie Morley on 31/03/2022.
//

import Foundation

public extension URL {

    var components: URLComponents? {
        return URLComponents(string: absoluteString)
    }

    func settingQueryItems(_ queryItems: [URLQueryItem]) -> URL? {
        guard var components = components else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }

}
