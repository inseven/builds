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

public struct WorkflowInstance: Identifiable, Hashable, Codable {

    public var attributedTitle: AttributedString? {
        guard let title else {
            return nil
        }
        guard let attributedTitle = try? AttributedString(markdown: title) else {
            return AttributedString(title)
        }
        return attributedTitle
    }

    public var branchURL: URL? {
        return repositoryURL?.appendingPathComponents(["tree", id.branch])
    }

    public var commitURL: URL? {
        guard let repositoryURL, let sha else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["commit", sha])
    }

    public var organizationURL: URL? {
        return repositoryURL?.deletingLastPathComponent()
    }

    public var pullsURL: URL? {
        return repositoryURL?.appendingPathComponent("pulls")
    }

    public var repositoryName: String {
        return id.repositoryName
    }

    public var shortSha: String? {
        return sha?.stringPrefix(7)
    }

    public var statusColor: Color {
        return operationState.color
    }

    public var systemImage: String {
        return operationState.systemImage
    }

    public var workflowFileURL: URL? {
        guard let repositoryURL, let workflowRunId else {
            return nil
        }
        return repositoryURL.appendingPathComponents(["actions", "runs", String(workflowRunId), "workflow"])
    }

    public let id: WorkflowIdentifier

    public let annotations: [Annotation]
    public let createdAt: Date?
    public let jobs: [Job]
    public let operationState: OperationState
    public let repositoryURL: URL?
    public let sha: String?
    public let title: String?
    public let updatedAt: Date?
    public let workflowFilePath: String?
    public let workflowName: String
    public let workflowRunAttempt: Int?
    public let workflowRunId: Int?
    public let workflowRunURL: URL?

    public init(id: ID, result: WorkflowResult? = nil) {
        self.id = id

        self.annotations = result?.annotations ?? []
        self.createdAt = result?.workflowRun.created_at
        self.jobs = (result?.jobs ?? []).map { Job($0) }
        self.operationState = OperationState(status: result?.workflowRun.status,
                                             conclusion: result?.workflowRun.conclusion)
        self.repositoryURL = result?.workflowRun.repository.html_url
        self.sha = result?.workflowRun.head_sha
        self.title = result?.workflowRun.display_title
        self.updatedAt = result?.workflowRun.updated_at
        self.workflowFilePath = result?.workflowRun.path
        self.workflowName = result?.workflowRun.name ?? id.workflowNameSnapshot
        self.workflowRunAttempt = result?.workflowRun.run_attempt
        self.workflowRunId = result?.workflowRun.id
        self.workflowRunURL = result?.workflowRun.html_url
    }

    public init(id: ID,
                annotations: [Annotation],
                createdAt: Date?,
                jobs: [Job],
                operationState: OperationState,
                repositoryURL: URL?,
                sha: String?,
                title: String?,
                updatedAt: Date?,
                workflowFilePath: String?,
                workflowName: String,
                workflowRunAttempt: Int?,
                workflowRunId: Int?,
                workflowRunURL: URL?) {
        self.id = id
        self.annotations = annotations
        self.createdAt = createdAt
        self.jobs = jobs
        self.operationState = operationState
        self.repositoryURL = repositoryURL
        self.sha = sha
        self.title = title
        self.updatedAt = updatedAt
        self.workflowFilePath = workflowFilePath
        self.workflowName = workflowName
        self.workflowRunAttempt = workflowRunAttempt
        self.workflowRunId = workflowRunId
        self.workflowRunURL = workflowRunURL
    }

    public func job(for annotation: Annotation) -> Job? {
        return jobs.first {
            return $0.id == annotation.jobId
        }
    }

}

extension Collection where Element == WorkflowInstance {

    public func sortedByDateDescending() -> [WorkflowInstance] {
        return sorted {
            let date0 = $0.createdAt ?? .distantPast
            let date1 = $1.createdAt ?? .distantPast
            return date0.compare(date1) == .orderedDescending
        }
    }

}
