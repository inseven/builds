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

public struct KeyedContainer {

    // TODO: Rename?
    // TODO: Hide this and make this Sequence / iterable
    let fields: [String: Any]

    public init(fields: [String: Any]) {
        self.fields = fields
    }

    // TODO: Doing it with an iniit like this feels messy at this point, but maybe it's more reusable?
    public init(from container: KeyedDecodingContainer<UnknownCodingKey>,
                selections: [any Selectable]) throws {
        var fields: [String: Any] = [:]
        for selection in selections {
            let keyedContainer = try selection.decode(container)
            for (key, value) in keyedContainer.fields {
                fields[key] = value
            }
        }
        self.fields = fields
    }

    // TODO: Throws?
    public subscript<T>(key: Selection<T>) -> Selection<T>.Datatype {
        get throws {
            guard let value = fields[key.resultKey] as? Selection<T>.Datatype else {
                throw BuildsError.unexpectedType
            }
            return value
        }
    }

    // TODO: Test convenience
    public subscript(key: String) -> KeyedContainer {
        get {
            return fields[key] as! KeyedContainer
        }
    }

}

// TODO: Move elsewhere!
extension KeyedDecodingContainer where K == UnknownCodingKey {

    public func decode<T: Decodable>(_ selection: Selection<T>) throws -> T {
        return try decode(T.self, forKey: UnknownCodingKey(stringValue: selection.resultKey)!)
    }

}

