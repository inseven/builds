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
    private let _decode: (String, KeyedDecodingContainer<UnknownCodingKey>) throws -> KeyedContainer

    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKey>) throws -> KeyedContainer {
        return try self._decode(resultKey, container)
    }

    public init(name: String,
                alias: String? = nil,
                arguments: [String : Argument] = [:],
                @SelectionBuilder selections: () -> [any Selectable],
                // TODO: This transform should take a Decoder instead?
                transform: @escaping (String, KeyedDecodingContainer<UnknownCodingKey>) -> KeyedContainer) {
        self.selections = selections()
        self.name = name
        self.alias = alias
        self.arguments = arguments
        self._decode = transform
    }

}

// TODO: We should constrain our children selections here to guarnatee that they're dictionaries. Like, can they actually
// be anything else? Maybe not???? Oh they probably can't be. Maybe these alwways need to returned a KeyedContainer!!
public struct Fragment: Selectable {

    public typealias Datatype = KeyedContainer

    public let prefix: String
    public let selections: [any Selectable]

    // TODO: Use the convenience constructor.
    public init(_ condition: String, @SelectionBuilder selections: () -> [any Selectable]) {
        self.prefix = condition
        self.selections = selections()
    }

    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKey>) throws -> KeyedContainer {
        let fields = try self.selections.map { try $0.decode(container) }
            .reduce(into: [String: Any]()) { partialResult, keyedContainer in
                for (key, value) in keyedContainer.fields {
                    partialResult[key] = value
                }
            }
        return KeyedContainer(fields: fields)
    }

}

extension Selection where Datatype == KeyedContainer {

    // TODO: We should probably warn/crash on selection collisions
    // TODO: Use the convenience constructor.
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
            let key = UnknownCodingKey(stringValue: resultKey)!
            let container = try container.nestedContainer(keyedBy: UnknownCodingKey.self, forKey: key)
            return KeyedContainer(fields: [resultKey: try KeyedContainer(from: container, selections: selections)])
        }
    }

}

extension Selection where Datatype: StaticSelectableContainer {

    // TODO: Use the convenience constructor.
    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:]) {

        let selections = Datatype.selections()

        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = selections
        self._decode = { resultKey, container in
            let key = UnknownCodingKey(stringValue: resultKey)!
            let container = try container.nestedContainer(keyedBy: UnknownCodingKey.self, forKey: key)
            return KeyedContainer(fields: [resultKey: try Datatype(from: container)])
        }
    }

}

extension Selection where Datatype: StaticSelectable {

    // TODO: Use the convenience constructor.
    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:]) {

        self.name = name
        self.alias = alias
        self.arguments = arguments
        self.selections = []
        self._decode = { resultKey, container in
            let key = UnknownCodingKey(stringValue: resultKey)!
            let decoder = try container.superDecoder(forKey: key)
            let singleValueContainer = try decoder.singleValueContainer()
            return KeyedContainer(fields: [resultKey: try Datatype(from: singleValueContainer)])
        }
    }

    // TODO: This feels like a hack.
    public init(_ name: CodingKey) {
        self.init(name.stringValue)
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
            var container = try container.nestedUnkeyedContainer(forKey: UnknownCodingKey(stringValue: resultKey)!)
            var results: [KeyedContainer] = []
            while !container.isAtEnd {
                let childContainer = try container.nestedContainer(keyedBy: UnknownCodingKey.self)
                results.append(try KeyedContainer(from: childContainer, selections: selections))
            }
            return KeyedContainer(fields: [resultKey: results])
        }
    }

}

extension Selection where Datatype == Array<StaticSelectableContainer> {

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
            var container = try container.nestedUnkeyedContainer(forKey: UnknownCodingKey(stringValue: resultKey)!)
            var results: [KeyedContainer] = []
            while !container.isAtEnd {
                let childContainer = try container.nestedContainer(keyedBy: UnknownCodingKey.self)
                results.append(try KeyedContainer(from: childContainer, selections: selections))
            }
            return KeyedContainer(fields: [resultKey: results])
        }
    }

}
