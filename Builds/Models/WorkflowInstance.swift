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

import BuildsCore

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

    var attributedTitle: AttributedString? {
        guard let title = result?.workflowRun.display_title else {
            return nil
        }
        guard let attributedTitle = try? AttributedString(markdown: title) else {
            return AttributedString(title)
        }
        return attributedTitle
    }

    var branchURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["tree", id.branch])
    }

    var commitURL: URL? {
        guard let result, let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["commit", result.workflowRun.head_sha])
    }

    var jobs: [GitHub.WorkflowJob] {
        return result?.jobs ?? []
    }

    var createdAt: Date? {
        return result?.workflowRun.created_at
    }

    var lastRun: String {
        guard let createdAt else {
            return "Unknown"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var operationState: OperationState {
        return OperationState(status: result?.workflowRun.status, conclusion: result?.workflowRun.conclusion)
    }

    var organizationURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.deletingLastPathComponent()
    }

    var pullsURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponent("pulls")
    }

    var repositoryName: String {
        return id.repositoryName
    }

    var repositoryURL: URL? {
        guard let url = result?.workflowRun.repository.html_url else {
            return nil
        }
        return url
    }

    var sha: String? {
        guard let result else {
            return nil
        }
        return String(result.workflowRun.head_sha.prefix(7))
    }

    var statusColor: Color {
        return summary.color
    }

    var summary: OperationState.Summary {
        return operationState.summary
    }

    var workflowName: String {
        return result?.workflowRun.name ?? String(id.workflowId)
    }

    var workflowURL: URL? {
        guard let repositoryURL, let id = result?.workflowRun.id else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["actions", "runs", String(id), "workflow"])
    }

    let id: ID
    let result: WorkflowResult?

    init(id: ID, result: WorkflowResult? = nil) {
        self.id = id
        self.result = result
    }

}
