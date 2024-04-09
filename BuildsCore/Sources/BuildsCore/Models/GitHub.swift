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

public enum GitHubError: Error {
    case invalidUrl
    case unauthorized
}

public class GitHub {

    private struct AccessToken: Codable {

        let access_token: String
        let scope: String
        let token_type: String
    }

    public struct Workflow: Codable, Identifiable, Equatable, Hashable {

        public static func == (lhs: Workflow, rhs: Workflow) -> Bool {
            return lhs.id == rhs.id
        }

        public let id: Int

        public let name: String
        public let node_id: String
        public let path: String
        public let state: String
    }

    public struct Workflows: Codable {

        public let total_count: Int
        public let workflows: [Workflow]
    }

    public struct Repositories: Codable {

        public let incomplete_results: Bool
        public let items: [Repository]
        public let total_count: Int
    }

    public struct Repository: Codable, Identifiable, Equatable, Hashable {

        public static func == (lhs: Repository, rhs: Repository) -> Bool {
            return lhs.id == rhs.id
        }
        
        public let id: Int

        public let archived: Bool
        public let default_branch: String
        public let full_name: String
        public let name: String
        public let node_id: String
        public let owner: User
        public let url: URL
    }

    public struct WorkflowRuns: Codable {

        public let total_count: Int
        public let workflow_runs: [WorkflowRun]
    }

    public struct WorkflowJobs: Codable {

        public let jobs: [WorkflowJob]
        public let total_count: Int

    }

    public struct WorkflowJob: Codable, Hashable, Identifiable {

        public let id: Int

        public let completed_at: Date?
        public let conclusion: Conclusion?
        public let html_url: URL
        public let name: String
        public let run_id: Int
        public let started_at: Date?
        public let status: Status
    }

    public struct Branch: Codable, Identifiable, Hashable {

        public var id: String {
            return name
        }

        public let name: String
    }

    public enum Status: String, Codable {
        case queued = "queued"
        case waiting = "waiting"
        case inProgress = "in_progress"
        case completed = "completed"
    }

    public enum Conclusion: String, Codable {
        case success
        case cancelled
        case failure
        case skipped
    }

    public struct WorkflowRun: Codable, Identifiable, Hashable {

        public struct Repository: Codable, Hashable {
            public let branches_url: URL
            public let full_name: String
            public let html_url: URL
        }

        public let id: Int

        public let check_suite_id: Int
        public let check_suite_node_id: String
        public let conclusion: Conclusion?
        public let created_at: Date
        public let display_title: String
        public let event: String
        public let head_branch: String
        public let head_sha: String
        public let html_url: URL
        public let name: String
        public let node_id: String
        public let path: String
        public let repository: Repository
        public let rerun_url: URL
        public let run_attempt: Int
        public let run_number: Int
        public let status: Status
        public let updated_at: Date
        public let url: URL
        public let workflow_id: Int
    }

    public struct Organization: Codable, Identifiable {

        public let id: Int

        public let login: String
    }

    public struct User: Codable, Hashable {

        public let login: String
        public let id: Int
        public let node_id: String
        public let avatar_url: URL
    }

    public enum Level: String, Codable {
        case failure
        case warning
    }

    public struct Annotation: Codable, Hashable {

        public let annotation_level: Level
        public let end_column: Int?
        public let end_line: Int
        public let message: String
        public let path: String
        public let start_column: Int?
        public let start_line: Int
        public let title: String
    }

    public enum Path: String {
        case authorize = "/login/oauth/authorize"
        case accessToken = "/login/oauth/access_token"
        case settingsConnectionsApplications = "/settings/connections/applications"
    }

    private let clientId: String
    private let clientSecret: String
    private let redirectUri: String

    private let syncQueue = DispatchQueue(label: "GitHub.syncQueue")

    public var authorizationURL: URL {
        return url(.authorize, parameters: [
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "scope": "workflow repo",
        ])!
    }

    public var permissionsURL: URL {
        return url(.settingsConnectionsApplications)!.appendingPathComponent(clientId)
    }

    public init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }

    private func fetch(_ url: URL, accessToken: String, method: String = "GET") async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try response.checkHTTPStatusCode()
        return data
    }

    private func fetch<T: Decodable>(_ url: URL, accessToken: String) async throws -> T {
        let data = try await fetch(url, accessToken: accessToken)
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
                                     accessToken: String,
                                     page: Int,
                                     perPage: Int = 30) async throws -> T {
        guard let url = url.settingQueryItems([
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
        ]) else {
            throw GitHubError.invalidUrl
        }
        let response: T = try await fetch(url, accessToken: accessToken)
        return response
    }

    public func rerun(repositoryName: String, workflowRunId: Int, accessToken: String) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs/\(workflowRunId)/rerun")!
        _ = try await fetch(url, accessToken: accessToken, method: "POST")
    }

    public func rerunFailedJobs(repositoryName: String, workflowRunId: Int, accessToken: String) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs/\(workflowRunId)/rerun-failed-jobs")!
        _ = try await fetch(url, accessToken: accessToken, method: "POST")
    }

    public func workflowRuns(repositoryName: String,
                             page: Int?,
                             perPage: Int?,
                             accessToken: String) async throws -> [WorkflowRun] {
        var queryItems: [URLQueryItem] = []
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let perPage {
            queryItems.append(URLQueryItem(name: "per_page", value: String(perPage)))
        }
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs")!
            .settingQueryItems(queryItems)!
        let response: WorkflowRuns = try await fetch(url, accessToken: accessToken)
        return response.workflow_runs
    }

    // TODO: Paged fetch
    public func repositories(accessToken: String) async throws -> [Repository] {
        var repositories: [Repository] = []
        for page in 1... {
            let url = URL(string: "https://api.github.com/user/repos")!
            let response: [Repository] = try await fetch(url, accessToken: accessToken, page: page, perPage: 100)
            repositories += response
            if response.isEmpty {
                break
            }
        }
        return repositories
    }

    // TODO: Owner and repo as parameters.
    public func branches(for repository: Repository, accessToken: String) async throws -> [Branch] {
        let url = URL(string: "https://api.github.com/repos/\(repository.full_name)/branches")!
        let response: [Branch] = try await fetch(url, accessToken: accessToken)
        return response
    }

    // TODO: Owner and repo as parameters.
    public func workflows(for repository: Repository, accessToken: String) async throws -> [Workflow] {
        let url = URL(string: "https://api.github.com/repos/\(repository.full_name)/actions/workflows")!
        let response: Workflows = try await fetch(url, accessToken: accessToken)
        return response.workflows
    }

    public func organizations(accessToken: String) async throws -> [Organization] {
        let url = URL(string: "https://api.github.com/users/jbmorley/orgs")!
        let response: [Organization] = try await fetch(url, accessToken: accessToken)
        return response
    }

    public func workflowJobs(for repositoryName: String,
                            workflowRun: WorkflowRun,
                            accessToken: String) async throws -> [WorkflowJob] {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/actions/runs/\(workflowRun.id)/jobs")!
        let response: WorkflowJobs = try await fetch(url, accessToken: accessToken)
        return response.jobs
    }

    public func annotations(for repositoryName: String,
                            workflowJob: WorkflowJob,
                            accessToken: String) async throws -> [Annotation] {
        let url = URL(string: "https://api.github.com/repos/\(repositoryName)/check-runs/\(workflowJob.id)/annotations")!
        let response: [Annotation] = try await fetch(url, accessToken: accessToken)
        return response
    }

    public func authenticate(with code: String) async throws -> String {
        guard let url = url(.accessToken, parameters: [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code
        ]) else {
            throw GitHubError.invalidUrl
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        try response.checkHTTPStatusCode()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let accessToken = try decoder.decode(AccessToken.self, from: data)
        return accessToken.access_token
    }

    public func deleteGrant(accessToken: String) async throws {
        // This end-point is a little unnusual:
        // https://docs.github.com/en/rest/apps/oauth-applications?apiVersion=2022-11-28#delete-an-app-authorization
        // https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28#using-basic-authentication

        let url = URL(string: "https://api.github.com/applications/\(clientId)/grant")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        guard let basicAuthentication = [clientId, clientSecret]
            .joined(separator: ":")
            .data(using: .utf8)?
            .base64EncodedString() else {
            throw BuildsError.authenticationFailure
        }
        request.setValue("Basic \(basicAuthentication)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode([
            "access_token": accessToken,
        ])

        let (_, response) = try await URLSession.shared.data(for: request)
        try response.checkHTTPStatusCode()
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
