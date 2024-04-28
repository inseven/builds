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

// TODO: Extract the selection key into a separate correlated protocol?
public struct Selection<T: Resultable>: IdentifiableSelection {

    public typealias Datatype = T

    public let name: String
    public let arguments: [String: Argument]
    public let alias: String?

    public var resultKey: String {
        return alias ?? name
    }

    private let _selections: [any IdentifiableSelection]

    public var selections: [any IdentifiableSelection] {
        return _selections
    }

    // TODO: We should get rid of the resultable at some point, but for the time being I think we can keep it?
    // TODO: We'll need to think of a better way to implement Resultable such that we don't need to capture the ID.
    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> Datatype {
        let decoder = MyDecoder(key: UnknownCodingKeys(stringValue: resultKey)!, container: container)
        return try Datatype(from: decoder, selections: selections)
    }

}

//public struct Fragment: IdentifiableSelection {
//
//    private let _selections: [any IdentifiableSelection]
//
//    public init(@SelectionBuilder selections: () -> [any IdentifiableSelection]) {
//        self._selections = selections()
//    }
//
//    public func selections() -> [any IdentifiableSelection] {
//        return _selections
//    }
//
//}

extension Selection where Datatype == KeyedContainer {

    // TODO: We should probably warn/crash on selection collisions
    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:],
                @SelectionBuilder selection: () -> [any IdentifiableSelection]) {
        self.name = name
        self.alias = alias
        self.arguments = arguments
        self._selections = selection()
    }

}

extension Selection where Datatype: StaticSelectable {

    public init(_ name: String,
                alias: String? = nil,
                arguments: [String: Argument] = [:]) {
        self.name = name
        self.alias = alias
        self.arguments = arguments
        self._selections = Datatype.selections()
    }

    public init(_ name: CodingKey) {
        self.name = name.stringValue
        self.alias = nil
        self.arguments = [:]
        self._selections = Datatype.selections()
    }

}
