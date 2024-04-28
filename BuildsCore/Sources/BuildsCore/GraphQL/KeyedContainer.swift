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

public struct KeyedContainer: Resultable {

    // TODO: Rename?
    let fields: [String: Any]

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        var fields: [String: Any] = [:]
        for selection in selections {
            let codingKey = UnknownCodingKeys(stringValue: selection.resultKey)!
            fields[selection.resultKey] = try selection.result(with: container,
                                                           codingKey: codingKey,
                                                           selections: selection.selections())
        }
        self.fields = fields
    }

    public subscript<T: Resultable>(key: Selection<T>) -> Selection<T>.Datatype {
        get {
            return fields[key.resultKey] as! Selection<T>.Datatype
        }
    }

}
