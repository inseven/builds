//
//  GitHubClient.swift
//  Status
//
//  Created by Jason Barrie Morley on 02/04/2022.
//

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

    func authorizationUrl() -> URL {
        return api.authorizationUrl
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
