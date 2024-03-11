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

enum GitHubError: Error {
    case invalidUrl
    case unauthorized
}

class GitHub {

    struct Authentication: RawRepresentable {

        let accessToken: String

        init(accessToken: String) {
            self.accessToken = accessToken
        }

        init?(rawValue: String) {
            guard !rawValue.isEmpty else {
                return nil
            }
            self.accessToken = rawValue
        }

        var rawValue: String {
            return accessToken
        }

    }

    private struct AccessToken: Codable {

        let access_token: String
        let scope: String
        let token_type: String
    }

    struct Workflow: Codable, Identifiable, Equatable, Hashable {

        static func == (lhs: Workflow, rhs: Workflow) -> Bool {
            return lhs.id == rhs.id
        }

        let id: Int

        let name: String
        let node_id: String
        let path: String
        let state: String
    }

    struct Workflows: Codable {

        let total_count: Int
        let workflows: [Workflow]
    }

    struct Repositories: Codable {

        let incomplete_results: Bool
        let items: [Repository]
        let total_count: Int
    }

    struct Repository: Codable, Identifiable, Equatable, Hashable {

        static func == (lhs: Repository, rhs: Repository) -> Bool {
            return lhs.id == rhs.id
        }
        
        let id: Int

        let archived: Bool
        let default_branch: String
        let full_name: String
        let name: String
        let node_id: String
        let owner: User
        let url: URL
    }

    struct WorkflowRuns: Codable {

        let total_count: Int
        let workflow_runs: [WorkflowRun]
    }

    struct WorkflowJobs: Codable {

        let jobs: [WorkflowJob]
        let total_count: Int

    }

    struct WorkflowJob: Codable, Hashable, Identifiable {

        let id: Int

        let conclusion: Conclusion?
        let html_url: URL
        let name: String
        let run_id: Int
        let status: Status
    }

    struct Branch: Codable, Identifiable, Hashable {

        var id: String {
            return name
        }

        let name: String
    }

    enum Status: String, Codable {
        case queued = "queued"
        case waiting = "waiting"
        case inProgress = "in_progress"
        case completed = "completed"
    }

    enum Conclusion: String, Codable {
        case success
        case cancelled
        case failure
    }

    struct WorkflowRun: Codable, Identifiable {

        let id: Int

        let check_suite_id: Int
        let check_suite_node_id: String
        let conclusion: Conclusion?
        let created_at: Date
        let event: String
        let head_branch: String
        let head_sha: String
        let html_url: URL
        let name: String
        let node_id: String
        let rerun_url: URL
        let run_attempt: Int
        let run_number: Int
        let status: Status
        let updated_at: Date
        let url: URL
        let workflow_id: Int
    }

    struct Organization: Codable, Identifiable {

        let id: Int

        let login: String
    }

    struct User: Codable, Hashable {

        let login: String
        let id: Int
        let node_id: String
        let avatar_url: URL
    }

    enum Level: String, Codable {
        case failure
        case warning
    }

    struct Annotation: Codable, Hashable {

        let annotation_level: Level
        let end_column: Int?
        let end_line: Int
        let message: String
        let path: String
        let start_column: Int?
        let start_line: Int
        let title: String
    }

    // TODO: Paged fetch

    enum Path: String {
        case authorize = "/login/oauth/authorize"
        case accessToken = "/login/oauth/access_token"
        case settingsConnectionsApplications = "/settings/connections/applications"
    }

    let clientId: String
    let clientSecret: String
    let redirectUri: String

    let syncQueue = DispatchQueue(label: "GitHub.syncQueue")

    var authorizationURL: URL {
        return url(.authorize, parameters: [
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "scope": "workflow repo",
        ])!
    }

    var permissionsURL: URL {
        return url(.settingsConnectionsApplications)!.appendingPathComponent(clientId)
    }

    init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }

    private func fetch<T: Decodable>(_ url: URL, authentication: Authentication) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(authentication.accessToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print(String(data: data, encoding: .utf8) ?? "nil")
            throw error
        }
    }

    private func fetch<T: Decodable>(_ url: URL,
                                     authentication: Authentication,
                                     page: Int,
                                     perPage: Int = 30) async throws -> T {
        guard let url = url.settingQueryItems([
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
        ]) else {
            throw GitHubError.invalidUrl
        }
        let response: T = try await fetch(url, authentication: authentication)
        return response
    }

    // TODO: Remove the 'for'
    func workflowRuns(for repositoryName: String, authentication: Authentication) async throws -> [WorkflowRun] {
        // TODO: Assemble the path?
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs")!
        let response: WorkflowRuns = try await fetch(url, authentication: authentication)
        return response.workflow_runs
    }

    // TODO: Paged fetch
    func repositories(authentication: Authentication) async throws -> [Repository] {
        var repositories: [Repository] = []
        for page in 1... {
            let url = URL(string: "https://api.github.com/user/repos")!
            let response: [Repository] = try await fetch(url, authentication: authentication, page: page, perPage: 100)
            repositories += response
            if response.isEmpty {
                break
            }
        }
        return repositories
    }

    // TODO: Owner and repo as parameters.
    func branches(for repository: Repository, authentication: Authentication) async throws -> [Branch] {
        let url = URL(string: "https://api.github.com/repos/\(repository.full_name)/branches")!
        let response: [Branch] = try await fetch(url, authentication: authentication)
        return response
    }

    // TODO: Use repositoryname
    func workflows(for repository: Repository, authentication: Authentication) async throws -> [Workflow] {
        let url = URL(string: "https://api.github.com/repos/\(repository.full_name)/actions/workflows")!
        let response: Workflows = try await fetch(url, authentication: authentication)
        return response.workflows
    }

    func organizations(authentication: Authentication) async throws -> [Organization] {
        let url = URL(string: "https://api.github.com/users/jbmorley/orgs")!
        let response: [Organization] = try await fetch(url, authentication: authentication)
        return response
    }

    func workflowJobs(for repositoryName: String,
                      workflowRun: WorkflowRun,
                      authentication: Authentication) async throws -> [WorkflowJob] {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs/\(workflowRun.id)/jobs")!
        let response: WorkflowJobs = try await fetch(url, authentication: authentication)
        return response.jobs
    }

    func annotations(for repositoryName: String, workflowJob: WorkflowJob, authentication: Authentication) async throws -> [Annotation] {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/check-runs/\(workflowJob.id)/annotations")!
        let response: [Annotation] = try await fetch(url, authentication: authentication)
        return response
    }

    // TODO: This could throw? Might be nicer?
    func authenticate(with code: String) async -> Result<Authentication, Error> {
        do {
            guard let url = url(.accessToken, parameters: [
                "client_id": clientId,
                "client_secret": clientSecret,
                "code": code
            ]) else {
                throw GitHubError.invalidUrl
            }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let accessToken = try decoder.decode(AccessToken.self, from: data)
            return .success(Authentication(accessToken: accessToken.access_token))
        } catch {
            return .failure(error)
        }
    }

    private func url(_ path: Path, parameters: [String: String] = [:]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = path.rawValue
        components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        return components.url
    }

}
