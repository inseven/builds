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

// Structs whose selection can be defined statically.
public protocol StaticSelectable: Resultable {

    @SelectionBuilder static func selections() -> [any IdentifiableSelection]

}

extension String: StaticSelectable {

    @SelectionBuilder public static func selections() -> [any IdentifiableSelection] {}

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        self = try container.decode(String.self, forKey: key)
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(String.self)
    }

}

extension Int: StaticSelectable {

    @SelectionBuilder public static func selections() -> [any IdentifiableSelection] {}

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(Int.self)
    }

}
