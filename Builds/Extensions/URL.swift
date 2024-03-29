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

    static let auth = URL(string: "x-builds-auth://oauth")!
    static let main = URL(string: "x-builds://main")!
    static let manageWorkflows = URL(string: "x-builds://manage-workflows")!

    static let gitHub = URL(string: "https://github.com")!

    var components: URLComponents? {
        return URLComponents(string: absoluteString)
    }

    init?(repositoryFullName: String) {
        self = Self.gitHub
            .appendingPathComponent(repositoryFullName)
    }

    init?(repositoryFullName: String, commit: String) {
        self = Self.gitHub
            .appendingPathComponent(repositoryFullName)
            .appendingPathComponent("commit")
            .appendingPathComponent(commit)
    }

    func settingQueryItems(_ queryItems: [URLQueryItem]) -> URL? {
        guard var components = components else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }

}
