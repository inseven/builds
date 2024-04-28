// Copyright (c) 2022-2024 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public struct Selection<T>: Selectable {

    public typealias Datatype = T

    public var prefix: String {
        var prefix = name
        if !arguments.isEmpty {
            let arguments = arguments.map { key, value in
                return "\(key): \(value.representation())"
            }
            .joined(separator: ", ")
            prefix = "\(prefix)(\(arguments))"
        }
        if let alias {
            prefix = "\(alias):\(prefix)"
        }
        return prefix
    }

    public var resultKey: String {
        return alias ?? name
    }

    public let selections: [any Selectable]

    private let name: String
    private let alias: String?
    private let arguments: [String: Argument]
    private let _decode: (String, KeyedDecodingContainer<UnknownCodingKeys>) throws -> (String?, Datatype)

    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> (String?, Datatype) {
        return try self._decode(resultKey, container)
    }

}

// TODO: We should constrain our children selections here to guarnatee that they're dictionaries. Like, can they actually
// be anything else? Maybe not???? Oh they probably can't be. Maybe these alwways need to returned a KeyedContainer!!
public struct Fragment: Selectable {

    public typealias Datatype = KeyedContainer

    public let prefix: String
    public let selections: [any Selectable]

    public init(_ condition: String, @SelectionBuilder selections: () -> [any Selectable]) {
        self.prefix = condition
        self.selections = selections()
    }

    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> (String?, KeyedContainer) {
        let fields = try self.selections.map { try $0.decode(container) }
            .reduce(into: [String: Any]()) { partialResult, item in
                partialResult[item.0!] = item.1  // TODO: GRIM GRIM GRIM.
            }
        return (nil, KeyedContainer(fields: fields))
    }

}

extension Selection where Datatype == KeyedContainer {

    // TODO: We should probably warn/crash on selection collisions
    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:],
                @SelectionBuilder selections: () -> [any Selectable]) {

        let selections = selections()

        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = selections
        self._decode = { resultKey, container in
            // TODO: Assemble this inline!
            let decoder = MyDecoder(key: UnknownCodingKeys(stringValue: resultKey)!, container: container)
            return (resultKey, try KeyedContainer(from: decoder, selections: selections))
        }
    }

}

extension Selection where Datatype: StaticSelectable {

    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:]) {

        let selections = Datatype.selections()

        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = selections
        self._decode = { resultKey, container in
            // TODO: Assemble this inline!
            let decoder = MyDecoder(key: UnknownCodingKeys(stringValue: resultKey)!, container: container)
            return (resultKey, try Datatype(from: decoder))
        }
    }

    public init(_ name: CodingKey) {

        let selections = Datatype.selections()

        self.name = name.stringValue
        self.alias = nil
        self.arguments = [:]
        self.selections = selections
        self._decode = { resultKey, container in
            // TODO: Assemble this inline!
            let decoder = MyDecoder(key: UnknownCodingKeys(stringValue: resultKey)!, container: container)
            return (resultKey, try Datatype(from: decoder))
        }
    }

}

extension Selection where Datatype == Array<KeyedContainer> {

    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:],
                @SelectionBuilder selections: () -> [any Selectable]) {

        let selections = selections()

        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = selections
        self._decode = { resultKey, container in
            var container = try container.nestedUnkeyedContainer(forKey: UnknownCodingKeys(stringValue: resultKey)!)
            var results: [KeyedContainer] = []
            while !container.isAtEnd {
                let childContainer = try container.nestedContainer(keyedBy: UnknownCodingKeys.self)
                results.append(try KeyedContainer(from: childContainer, selections: selections))
            }

//            // TODO: Assemble this inline!
//            let decoder = MyDecoder(key: UnknownCodingKeys(stringValue: resultKey)!, container: container)
            return (resultKey, results)
        }
    }

}
