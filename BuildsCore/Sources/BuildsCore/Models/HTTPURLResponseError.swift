// Copyright (c) 2021-2025 Jason Morley
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

public enum HTTPURLResponseError: Error {

    case invalidResponse
    case httpError(HTTPStatusCode)

}

extension HTTPURLResponseError: LocalizedError {

    public var errorDescription: String? {

        switch self {
        case .invalidResponse:
            return "Response isn't HTTP"
        case .httpError(let statusCode):
            return statusCode.localizedDescription
        }

    }

}

extension URLResponse {

    func checkHTTPStatusCode(permitting statusCode: HTTPStatusCode) throws {
        return try self.checkHTTPStatusCode(permitting: [statusCode])
    }

    func checkHTTPStatusCode(permitting: Set<HTTPStatusCode> = .allSuccesses) throws {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw HTTPURLResponseError.invalidResponse
        }
        let statusCode = HTTPStatusCode(rawValue: httpResponse.statusCode)
        guard permitting.contains(statusCode) else {
            throw HTTPURLResponseError.httpError(statusCode)
        }
    }

}
