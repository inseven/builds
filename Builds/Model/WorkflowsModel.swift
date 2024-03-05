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

import Combine
import SwiftUI

import Interact

class WorkflowsModel: ObservableObject, Runnable {

    @MainActor @Published var repositories: [RepositoryDetails]?
    @MainActor @Published var error: Error?

    let applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    @MainActor func start() {
        updateRepositories()
    }

    @MainActor func stop() {

    }

    func updateRepositories() {
        let client = applicationModel.client
        Task {
            do {
                let repositories = try await client
                    .repositories()
                    .compactMap { repository -> RepositoryDetails? in
                        guard !repository.archived else {
                            return nil
                        }
                        let workflows = try await client.workflows(for: repository)
                        guard workflows.count > 0 else {
                            return nil
                        }
                        let branches = try await client.branches(for: repository)
                        return RepositoryDetails(repository: repository,
                                                 workflows: workflows,
                                                 branches: branches)
                    }
                    .sorted { $0.repository.fullName.localizedStandardCompare($1.repository.fullName) == .orderedAscending }
                await MainActor.run {
                    self.repositories = repositories
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

}