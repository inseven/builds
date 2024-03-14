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

protocol AuthenticationProvider: NSObject {

    @MainActor var authenticationToken: GitHub.Authentication? { get set }

}

class GitHubClient {

    private let api: GitHub
    weak var authenticationProvider: AuthenticationProvider?

    init(api: GitHub) {
        self.api = api
    }

    private func getAuthentication() async throws -> GitHub.Authentication {
        return try await withCheckedThrowingContinuation { completion in
            DispatchQueue.main.async {
                guard let authentication = self.authenticationProvider?.authenticationToken else {
                    completion.resume(throwing: GitHubError.unauthorized)
                    return
                }
                completion.resume(returning: authentication)
            }
        }
    }

    var authorizationURL: URL {
        return api.authorizationURL
    }

    var permissionsURL: URL {
        return api.permissionsURL
    }

    func authenticate(with code: String) async throws {
        let result = await api.authenticate(with: code)
        try await MainActor.run {
            switch result {
            case .success(let authentication):
                self.authenticationProvider?.authenticationToken = authentication
            case .failure(let error):
                self.authenticationProvider?.authenticationToken = nil
                throw error
            }
        }
    }

    func deleteGrant() async throws {
        try await api.deleteGrant(authentication: try getAuthentication())
    }

    // TODO: Wrapper that detects authentication failure.

    func organizations() async throws -> [GitHub.Organization] {
        return try await api.organizations(authentication: try getAuthentication())
    }

    func repositories() async throws -> [GitHub.Repository] {
        return try await api.repositories(authentication: try getAuthentication())
    }

    func workflowRuns(repositoryName: String,
                      seekingWorkflowIds: any Collection<WorkflowInstance.ID>) async throws -> [GitHub.WorkflowRun] {

        var workflowIds = Set<WorkflowInstance.ID>()
        let seekingWorkflowIds = Set(seekingWorkflowIds)
        var results = [GitHub.WorkflowRun]()
        for page in 1..<10 {
            let workflowRuns = try await api.workflowRuns(repositoryName: repositoryName,
                                                          page: page,
                                                          perPage: 100,
                                                          authentication: try getAuthentication())
            let responseWorkflowIds = await workflowRuns.map { workflowRun in
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
    func update(favorites: [WorkflowInstance.ID],
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
        let workflowJobs = try await self.workflowJobs(for: id.repositoryFullName, workflowRun: workflowRun)
        var annotations: [WorkflowResult.Annotation] = []
        for workflowJob in workflowJobs {
            let results = try await self
                .annotations(for: id.repositoryFullName, workflowJob: workflowJob)
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

    func branches(for repository: GitHub.Repository) async throws -> [GitHub.Branch] {
        return try await api.branches(for: repository, authentication: try getAuthentication())
    }

    func workflows(for repository: GitHub.Repository) async throws -> [GitHub.Workflow] {
        return try await api.workflows(for: repository, authentication: try getAuthentication())
    }

    func workflowJobs(for repositoryName: String,
                      workflowRun: GitHub.WorkflowRun) async throws -> [GitHub.WorkflowJob] {
        return try await api.workflowJobs(for: repositoryName,
                                          workflowRun: workflowRun,
                                          authentication: try getAuthentication())
    }

    func annotations(for repositoryName: String,
                     workflowJob: GitHub.WorkflowJob) async throws -> [GitHub.Annotation] {
        return try await api.annotations(for: repositoryName,
                                         workflowJob: workflowJob,
                                         authentication: try getAuthentication())
    }

}
