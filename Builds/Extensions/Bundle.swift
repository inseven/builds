//
//  Bundle.swift
//  Status
//
//  Created by Jason Barrie Morley on 11/04/2022.
//

import Foundation

extension Bundle {

    func configuration() -> Configuration {
        let url = Bundle.main.url(forResource: "configuration", withExtension: "json")!
        return try! Configuration(url: url)
    }

}
