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

public struct Annotation: Codable, Identifiable, Hashable {

    public enum Level: String, Codable {
        case failure
        case warning
    }

    public var id: String {
        return "\(path):\(startLine):\(endLine):\(startColumn ?? -1):\(endColumn ?? -1)"
    }

    public let jobId: Int

    public let endColumn: Int?
    public let endLine: Int
    public let level: Level
    public let message: String
    public let path: String
    public let startColumn: Int?
    public let startLine: Int
    public let title: String

    init(jobId: Int, annotation: GitHub.Annotation) {
        self.jobId = jobId

        self.endColumn = annotation.end_column
        self.endLine = annotation.end_line
        self.level = Level(annotation.annotation_level)
        self.message = annotation.message
        self.path = annotation.path
        self.startColumn = annotation.end_column
        self.startLine = annotation.start_line
        self.title = annotation.title
    }
}

extension Annotation.Level {

    init(_ level: GitHub.Level) {
        switch level {
        case .failure:
            self = .failure
        case .warning:
            self = .warning
        }
    }

}
