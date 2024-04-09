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

import Interact

public class GitHubClient {

    private let api: GitHub
    private let accessToken: String

    public init(api: GitHub, accessToken: String) {
        self.api = api
        self.accessToken = accessToken
    }

    public func repositories() async throws -> [GitHub.Repository] {
        return try await api.repositories(accessToken: accessToken)
    }

    public func workflowRuns(repositoryName: String,
                             seekingWorkflowIds: any Collection<WorkflowInstance.ID>) async throws -> [GitHub.WorkflowRun] {

        var workflowIds = Set<WorkflowInstance.ID>()
        let seekingWorkflowIds = Set(seekingWorkflowIds)
        var results = [GitHub.WorkflowRun]()
        for page in 1..<10 {
            let workflowRuns = try await api.workflowRuns(repositoryName: repositoryName,
                                                          page: page,
                                                          perPage: 100,
                                                          accessToken: accessToken)
            let responseWorkflowIds = workflowRuns.map { workflowRun in
                return WorkflowInstance.ID(repositoryFullName: repositoryName,
                                           workflowId: workflowRun.workflow_id,
                                           branch: workflowRun.head_branch)
            }
            workflowIds.formUnion(responseWorkflowIds)
            results.append(contentsOf: workflowRuns)
            if workflowRuns.isEmpty {
                break
            }
            if workflowIds.intersection(seekingWorkflowIds).count == seekingWorkflowIds.count {
                break
            }
        }
        return results
    }

    // Top level call that triggers fetching all workflow results.
    public func update(favorites: [WorkflowInstance.ID],
                       callback: @escaping (WorkflowInstance) -> Void) async throws {
        let repositories = favorites
            .reduce(into: [String: [WorkflowInstance.ID]]()) { partialResult, id in
                var ids = partialResult[id.repositoryFullName] ?? []
                ids.append(id)
                partialResult[id.id.repositoryFullName] = ids
            }
        try await repositories.asyncForEach { repository, ids in
            try await self.fetchDetails(repository: repository, ids: ids, callback: callback)
        }
    }

    // Fetch the workflow details from a single repository.
    private func fetchDetails(repository: String,
                              ids: [WorkflowInstance.ID],
                              callback: @escaping (WorkflowInstance) -> Void) async throws {

        // Search for workflow runs for each of our requested ids.
        let ids = Set(ids)
        let workflowRuns = try await self
            .workflowRuns(repositoryName: repository, seekingWorkflowIds: ids)
            .reduce(into: [WorkflowInstance.ID: GitHub.WorkflowRun]()) { partialResult, workflowRun in
                let id = WorkflowInstance.ID(repositoryFullName: workflowRun.repository.full_name,
                                             workflowId: workflowRun.workflow_id,
                                             branch: workflowRun.head_branch)
                guard partialResult[id] == nil else {
                    return
                }
                guard ids.contains(id) else {
                    return
                }
                partialResult[id] = workflowRun
            }

        // Flesh out the build details for each.
        try await workflowRuns.asyncForEach { id, workflowRun in
            try await self.fetchDetails(id: id, workflowRun: workflowRun, callback: callback)
        }
    }

    // Fetch the details for individual workflows.
    private func fetchDetails(id: WorkflowInstance.ID,
                              workflowRun: GitHub.WorkflowRun,
                              callback: @escaping (WorkflowInstance) -> Void) async throws {
        let workflowJobs = try await api.workflowJobs(for: id.repositoryFullName,
                                                      workflowRun: workflowRun,
                                                      accessToken: accessToken)
        var annotations: [WorkflowResult.Annotation] = []
        for workflowJob in workflowJobs {
            let results = try await api
                .annotations(for: id.repositoryFullName, workflowJob: workflowJob, accessToken: accessToken)
                .map {
                    return WorkflowResult.Annotation(jobId: workflowJob.id, annotation: $0)
                }
            annotations.append(contentsOf: results)
        }
        let workflowInstance = WorkflowInstance(id: id,
                                                result: WorkflowResult(workflowRun: workflowRun,
                                                                       jobs: workflowJobs,
                                                                       annotations: annotations))
        await MainActor.run {
            callback(workflowInstance)
        }
    }

    public func branches(for repository: GitHub.Repository) async throws -> [GitHub.Branch] {
        return try await api.branches(for: repository, accessToken: accessToken)
    }

    public func workflows(for repository: GitHub.Repository) async throws -> [GitHub.Workflow] {
        return try await api.workflows(for: repository, accessToken: accessToken)
    }

    public func rerun(repositoryName: String, workflowRunId: Int) async throws {
        return try await api.rerun(repositoryName: repositoryName,
                                   workflowRunId: workflowRunId,
                                   accessToken: accessToken)
    }

    public func rerunFailedJobs(repositoryName: String, workflowRunId: Int) async throws {
        return try await api.rerunFailedJobs(repositoryName: repositoryName,
                                             workflowRunId: workflowRunId,
                                             accessToken: accessToken)
    }


}
