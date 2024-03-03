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

class Action: Identifiable, Hashable, Codable {

    private enum CodingKeys: CodingKey {
        case repositoryName
        case repositoryFullName
        case workflowId
        case branch
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        return (
            lhs.id == rhs.id &&
            lhs.repositoryName == rhs.repositoryName &&
            lhs.repositoryFullName == rhs.repositoryFullName &&
            lhs.workflowId == rhs.workflowId &&
            lhs.branch == rhs.branch
        )
    }

    var id: String {
        return "\(repositoryFullName)@\(branch)"
    }

    let repositoryName: String
    let repositoryFullName: String
    let workflowId: Int
    let branch: String

    init(repositoryName: String, repositoryFullName: String, workflowId: Int, branch: String) {
        self.repositoryName = repositoryName
        self.repositoryFullName = repositoryFullName
        self.workflowId = workflowId
        self.branch = branch
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.repositoryName = try container.decode(String.self, forKey: .repositoryName)
        self.repositoryFullName = try container.decode(String.self, forKey: .repositoryFullName)
        self.workflowId = try container.decode(Int.self, forKey: .workflowId)
        self.branch = try container.decode(String.self, forKey: .branch)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repositoryName, forKey: .repositoryName)
        try container.encode(repositoryFullName, forKey: .repositoryFullName)
        try container.encode(workflowId, forKey: .workflowId)
        try container.encodeIfPresent(branch, forKey: .branch)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(repositoryName)
        hasher.combine(repositoryFullName)
        hasher.combine(workflowId)
        hasher.combine(branch)
    }

}
