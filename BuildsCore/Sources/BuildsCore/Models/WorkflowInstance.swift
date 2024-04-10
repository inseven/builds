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

public struct WorkflowInstance: Identifiable, Hashable {

    public var annotations: [WorkflowResult.Annotation] {
        return result?.annotations ?? []
    }

    public var attributedTitle: AttributedString? {
        guard let title = result?.workflowRun.display_title else {
            return nil
        }
        guard let attributedTitle = try? AttributedString(markdown: title) else {
            return AttributedString(title)
        }
        return attributedTitle
    }

    public var branchURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["tree", id.branch])
    }

    public var commitURL: URL? {
        guard let result, let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["commit", result.workflowRun.head_sha])
    }

    public var jobs: [GitHub.WorkflowJob] {
        return result?.jobs ?? []
    }

    public var createdAt: Date? {
        return result?.workflowRun.created_at
    }

    public var operationState: OperationState {
        return OperationState(status: result?.workflowRun.status, conclusion: result?.workflowRun.conclusion)
    }

    public var organizationURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.deletingLastPathComponent()
    }

    public var pullsURL: URL? {
        guard let repositoryURL else {
            return nil
        }
        return repositoryURL.appendingPathComponent("pulls")
    }

    public var repositoryName: String {
        return id.repositoryName
    }

    public var repositoryURL: URL? {
        guard let url = result?.workflowRun.repository.html_url else {
            return nil
        }
        return url
    }

    public var sha: String? {
        guard let result else {
            return nil
        }
        return String(result.workflowRun.head_sha.prefix(7))
    }

    public var statusColor: Color {
        return summary.color
    }

    public var summary: OperationState.Summary {
        return operationState.summary
    }

    public var systemImage: String {
        return operationState.systemImage
    }

    public var workflowName: String {
        return result?.workflowRun.name ?? String(id.workflowId)
    }

    public var workflowURL: URL? {
        guard let repositoryURL, let id = result?.workflowRun.id else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["actions", "runs", String(id), "workflow"])
    }

    public let id: WorkflowIdentifier
    public let result: WorkflowResult?

    public init(id: ID, result: WorkflowResult? = nil) {
        self.id = id
        self.result = result
    }

}
