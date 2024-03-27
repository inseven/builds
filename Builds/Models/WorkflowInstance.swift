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

import SwiftUI

struct WorkflowInstance: Identifiable, Hashable {

    struct ID: Hashable, Codable {

        var id: Self {
            return self
        }

        var organization: String {
            return String(repositoryFullName.split(separator: "/").first ?? "?")
        }

        var repositoryName: String {
            return String(repositoryFullName.split(separator: "/").last ?? "?")
        }

        let repositoryFullName: String
        let workflowId: Int
        let branch: String

        init(repositoryFullName: String, workflowId: Int, branch: String) {
            self.repositoryFullName = repositoryFullName
            self.workflowId = workflowId
            self.branch = branch
        }

    }

    var annotations: [WorkflowResult.Annotation] {
        return result?.annotations ?? []
    }

    var commitURL: URL? {
        guard let result else {
            return nil
        }
        return URL(repositoryFullName: id.repositoryFullName, commit: result.workflowRun.head_sha)
    }

    var details: String {
        return "\(workflowName) (\(id.branch))"
    }

    var lastRun: String {
        guard let createdAt = result?.workflowRun.created_at else {
            return "Unknown"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var repositoryName: String {
        return id.repositoryName
    }

    var repositoryURL: URL? {
        return URL(repositoryFullName: id.repositoryFullName)
    }

    var state: SummaryState {
        return SummaryState(status: result?.workflowRun.status,
                            conclusion: result?.workflowRun.conclusion)
    }

    var statusColor: Color {
        return state.color
    }

    var workflowName: String {
        return result?.workflowRun.name ?? String(id.workflowId)
    }

    let id: ID
    let result: WorkflowResult?

    init(id: ID, result: WorkflowResult? = nil) {
        self.id = id
        self.result = result
    }

}
