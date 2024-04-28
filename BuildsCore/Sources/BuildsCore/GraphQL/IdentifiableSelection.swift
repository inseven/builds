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

// Operation
// Field
// Fragment

// TODO: It really does make sense to fold all this stuff into NamedSelection we can likely get away with this alone.
// TODO: I think this is a field.
public protocol IdentifiableSelection: Selectable {

    var name: String { get }
    var alias: String? { get }
    var arguments: [String: Argument] { get }
    var resultKey: String { get }

}

extension IdentifiableSelection {

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

    public func result(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                       codingKey: UnknownCodingKeys,
                       selections: [any IdentifiableSelection]) throws -> Datatype {
        let decoder = MyDecoder(key: codingKey, container: container)
        return try Datatype(from: decoder, selections: selections)
    }

}
