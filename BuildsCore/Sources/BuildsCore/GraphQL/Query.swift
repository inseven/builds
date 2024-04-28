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

// TODO: Do queries always returned a named selection and is that how this works? That makes extra sense for the keyed container to be on the result type.
// I think the data type makes no sense here. Is this a side effect of getting the protocols insufficiently fine grained?
public struct Query: Selectable {

    public typealias Datatype = KeyedContainer

    public let prefix = "query"
    public let name = "query"  // TODO: Get rido fo this when we drop 'IdentifiableSelection'
    public let alias: String? = nil
    public let arguments: [String : Argument] = [:]
    public let resultKey = "data"

    private let _selections: [any Selectable]

    public init(@SelectionBuilder selection: () -> [any Selectable]) {
        self._selections = selection()
    }

    public var selections: [any Selectable] {
        return self._selections
    }

    public func decode(_ data: Data) throws -> Datatype {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [.selectable: self]
        return try decoder.decode(ResultWrapper<Self>.self, from: data).value
    }

    // TODO: This could easily be a block based transform if the Datatype doesn't support the init method.
    public func decode(_ container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> (String?, Datatype) {
        let container = try container.nestedContainer(keyedBy: UnknownCodingKeys.self,
                                                      forKey: UnknownCodingKeys(stringValue: "data")!)
        return ("data", try KeyedContainer(from: container, selections: selections))
    }

}
