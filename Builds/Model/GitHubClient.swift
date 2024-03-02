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

    enum ClientError: Error {
        case authenticationFailure
    }

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

    // TODO: Move this into the ApplicationModel.
    func authenticate(with url: URL) async -> Result<GitHub.Authentication, Error> {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "x-builds-auth",
              components.host == "oauth",
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            return .failure(ClientError.authenticationFailure)
        }
        return await authenticate(with: code)
    }

    func authenticate(with code: String) async -> Result<GitHub.Authentication, Error> {
        let result = await api.authenticate(with: code)
        await MainActor.run {
            switch result {
            case .success(let authentication):
                self.authenticationProvider?.authenticationToken = authentication
            case .failure(_):
                self.authenticationProvider?.authenticationToken = nil
            }
        }
        return result
    }

    @MainActor func logOut() {
        self.authenticationProvider?.authenticationToken = nil
    }

    // TODO: Wrapper that detects authentication failure.

    func organizations() async throws -> [GitHub.Organization] {
        return try await api.organizations(authentication: try getAuthentication())
    }

    func repositories() async throws -> [GitHub.Repository] {
        return try await api.repositories(authentication: try getAuthentication())
    }

    func workflowRuns(for repositoryName: String) async throws -> [GitHub.WorkflowRun] {
        return try await api.workflowRuns(for: repositoryName, authentication: try getAuthentication())
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
