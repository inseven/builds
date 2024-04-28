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

// TODO: Move into the IdentifiableSelection extension that yields a result?
// This is the magic that allows us to start the decoding stack by getting to the first-level container.
public struct ResultWrapper<T: Selectable>: Decodable {

    let value: T.Datatype

    public init(from decoder: any Decoder) throws {
        // TODO: There's some crashy type stuff here that shouldn't be crashy.
        let selectable = decoder.userInfo[.selectable] as! any Selectable
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        let (_, value) = try selectable.decode(container)
        self.value = value as! T.Datatype
    }

}
