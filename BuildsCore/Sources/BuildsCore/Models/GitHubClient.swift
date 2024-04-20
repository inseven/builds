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

    public struct WorkflowFetchOptions: OptionSet {
        public let rawValue: Int

        public static let jobs = WorkflowFetchOptions(rawValue: 1 << 0)

        public static let all: WorkflowFetchOptions = [.jobs]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    @MainActor public static var `default`: GitHubClient {
        get throws {
            let configuration = Configuration.shared
            let api = GitHub(clientId: configuration.clientId,
                             clientSecret: configuration.clientSecret,
                             redirectUri: "x-builds-auth://oauth")
            guard let accessToken = Settings().accessToken else {
                throw BuildsError.authenticationFailure
            }
            return GitHubClient(api: api, accessToken: accessToken)
        }
    }

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

    // Convenience for fetching results for a single workflow.
    public func fetch(id: WorkflowInstance.ID, options: WorkflowFetchOptions) async throws -> WorkflowInstance {
        return try await update(workflows: [id], options: []).first!
    }

    // Top level call that triggers fetching all workflow results.
    public func update(workflows: [WorkflowInstance.ID],
                       options: WorkflowFetchOptions = .all,
                       callback: ((WorkflowInstance) -> Void)? = nil) async throws -> [WorkflowInstance] {
        let repositories = workflows
            .reduce(into: [String: [WorkflowInstance.ID]]()) { partialResult, id in
                var ids = partialResult[id.repositoryFullName] ?? []
                ids.append(id)
                partialResult[id.repositoryFullName] = ids
            }
        return try await repositories
            .asyncMap { repository, ids in
                return try await self.fetchDetails(repository: repository, ids: ids, options: options, callback: callback)
            }
            .reduce(into: [WorkflowInstance]()) { partialResult, workflowInstances in
                partialResult.append(contentsOf: workflowInstances)
            }
    }

    // Fetch the workflow details from a single repository.
    private func fetchDetails(repository: String,
                              ids: [WorkflowInstance.ID],
                              options: WorkflowFetchOptions,
                              callback: ((WorkflowInstance) -> Void)?) async throws -> [WorkflowInstance] {

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
        return try await workflowRuns
            .asyncMap { id, workflowRun in
                return try await self.fetchDetails(id: id,
                                                   workflowRun: workflowRun,
                                                   options: options,
                                                   callback: callback)
            }
    }

    // Fetch the details for individual workflows.
    private func fetchDetails(id: WorkflowInstance.ID,
                              workflowRun: GitHub.WorkflowRun,
                              options: WorkflowFetchOptions,
                              callback: ((WorkflowInstance) -> Void)?) async throws -> WorkflowInstance {

        var workflowJobs: [GitHub.WorkflowJob] = []
        var annotations: [WorkflowResult.Annotation] = []

        if options.contains(.jobs) {
            workflowJobs = try await api.workflowJobs(for: id.repositoryFullName,
                                                      workflowRun: workflowRun,
                                                      accessToken: accessToken)

            for workflowJob in workflowJobs {
                let results = try await api
                    .annotations(for: id.repositoryFullName, workflowJob: workflowJob, accessToken: accessToken)
                    .map {
                        return WorkflowResult.Annotation(jobId: workflowJob.id, annotation: $0)
                    }
                annotations.append(contentsOf: results)
            }
        }

        let workflowInstance = WorkflowInstance(id: id,
                                                result: WorkflowResult(workflowRun: workflowRun,
                                                                       jobs: workflowJobs,
                                                                       annotations: annotations))
        await MainActor.run {
            callback?(workflowInstance)
        }

        return workflowInstance
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
