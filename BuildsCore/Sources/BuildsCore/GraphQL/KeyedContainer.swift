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

// TODO: We probably don't need half the constructors in here!
public struct KeyedContainer {

    // TODO: Rename?
    let fields: [String: Any]

    public init(fields: [String: Any]) {
        self.fields = fields
    }

    // TODO: Doing it with an iniit like this feels messy at this point, but maybe it's more reusable?
    public init(from container: KeyedDecodingContainer<UnknownCodingKeys>,
                selections: [any Selectable]) throws {
        var fields: [String: Any] = [:]
        for selection in selections {
            let (key, value) = try selection.decode(container)
            fields[key!] = value  // TODO: This seems problematic.
        }
        self.fields = fields
    }

    public init(from decoder: MyDecoder, selections: [any Selectable]) throws {
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        var fields: [String: Any] = [:]
        for selection in selections {
            let (key, value) = try selection.decode(container)

            // TODO: There's a lot of guesswork going on here and we should be able to make it typesafe.
            // TODO: I can probably do this with some kind of type conditions to mean you can't actually compile it if
            // this trick won't work?
            if let key {
                fields[key] = value
            } else if let keyedContainer = value as? KeyedContainer {
                for (key, value) in keyedContainer.fields {
                    fields[key] = value
                }
            } else {
                throw BuildsError.authenticationFailure
            }
        }
        self.fields = fields
    }

    public subscript<T>(key: Selection<T>) -> Selection<T>.Datatype {
        get {
            return fields[key.resultKey] as! Selection<T>.Datatype
        }
    }

}
