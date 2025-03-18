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

// TODO: This currently models two behaviours which feels wrong.
// Specifically, this models both containers and single value selectables.
public protocol StaticSelectableContainer {

    typealias DecodingContainer = KeyedDecodingContainer<UnknownCodingKey>

    // TODO: Push `SelectionBuilder` into the protocol? Does a var let us do this?
    @SelectionBuilder static func selections() -> [any Selectable]

    // TODO: Ideally this would take a KeyedContainer
    // TODO: Can we actually get away without the custom decoder if we pass in a single value container instead?
    init(from container: DecodingContainer) throws

}

// TODO: It might be possible to recombine these.
public protocol StaticSelectable {

    typealias DecodingContainer = SingleValueDecodingContainer

    init(from container: DecodingContainer) throws

}

extension String: StaticSelectable {

    public init(from container: DecodingContainer) throws {
        self = try container.decode(String.self)
    }

}

extension Int: StaticSelectable {

    public init(from container: DecodingContainer) throws {
        self = try container.decode(Int.self)
    }

}

extension Date: StaticSelectable {

    public init(from container: DecodingContainer) throws {
        self = try container.decode(Date.self)
    }

}
