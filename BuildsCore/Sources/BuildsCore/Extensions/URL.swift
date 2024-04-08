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

extension URL: Identifiable {

    public var id: Self {
        return self
    }

    public static let auth = URL(string: "x-builds-auth://oauth")!
    public static let main = URL(string: "x-builds://main")!
    public static let manageWorkflows = URL(string: "x-builds://manage-workflows")!

    public static let gitHub = URL(string: "https://github.com")!

    public var components: URLComponents? {
        return URLComponents(string: absoluteString)
    }

    public func settingQueryItems(_ queryItems: [URLQueryItem]) -> URL? {
        guard var components = components else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }

    public func appendingPathComponents(_ pathComponents: [String]) -> URL {
        return pathComponents.reduce(self) { partialResult, pathComponent in
            return partialResult.appendingPathComponent(pathComponent)
        }
    }

}
