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

// TODO: This must be run on a certain thread. Is there a way to annotate this?
class GitHubClient: ObservableObject {

    enum State {
        case unauthorized
        case authorized
    }

    private let api: GitHub
    private let authentication: Binding<GitHub.Authentication?>

    @Published var state: State

    init(api: GitHub, authentication: Binding<GitHub.Authentication?>) {
        self.api = api
        self.authentication = authentication
        _state = Published(initialValue: authentication.wrappedValue != nil ? .authorized : .unauthorized)
    }

    private func getAuthentication() async throws -> GitHub.Authentication {
        return try await withCheckedThrowingContinuation { completion in
            DispatchQueue.main.async {
                guard let authentication = self.authentication.wrappedValue else {
                    completion.resume(throwing: GitHubError.unauthorized)
                    return
                }
                completion.resume(returning: authentication)
            }
        }
    }

    // TODO: Maybe make this a variable?
    // TODO: Capitalisation
    func authorizationUrl() -> URL {
        return api.authorizationUrl
    }

    var permissionsURL: URL {
        return api.permissionsURL
    }

    enum ClientError: Error {
        case fuck
    }

    func authenticate(with url: URL) async -> Result<GitHub.Authentication, Error> {

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "x-builds-auth",
              components.host == "oauth",
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            return .failure(ClientError.fuck)
        }

        return await authenticate(with: code)
    }

    func authenticate(with code: String) async -> Result<GitHub.Authentication, Error> {
        let result = await api.authenticate(with: code)
        // TODO: Think of a better way to force us back to the correct thread.
        DispatchQueue.main.sync {
            switch result {
            case .success(let authentication):
                self.authentication.wrappedValue = authentication
                self.state = .authorized
            case .failure(_):
                self.authentication.wrappedValue = nil
                self.state = .unauthorized
            }
        }
        return result
    }

    // TODO: Ensure this runs on the correct thread?
    func logOut() {
        authentication.wrappedValue = nil
        state = .unauthorized
    }

    // TODO: Wrapper that detects authentication failure.

    func organizations() async throws -> [GitHub.Organization] {
        return try await api.organizations(authentication: try getAuthentication())
    }

    func repositories() async throws -> [GitHub.Repository] {
        guard let accessToken = authentication.wrappedValue else {
            throw GitHubError.unauthorized
        }
        return try await api.repositories(authentication: accessToken)
    }

    func workflowRuns(for repositoryName: String) async throws -> [GitHub.WorkflowRun] {
        return try await api.workflowRuns(for: repositoryName, authentication: try getAuthentication())
    }

    func branches(for repository: GitHub.Repository) async throws -> [GitHub.Branch] {
        return try await api.branches(for: repository, authentication: try getAuthentication())
    }

    // TODO: Fetch the workflow

    func workflows(for repository: GitHub.Repository) async throws -> [GitHub.Workflow] {
        return try await api.workflows(for: repository, authentication: try getAuthentication())
    }
}
