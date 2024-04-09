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

import AppIntents

import BuildsCore

struct WorkflowQuery: EntityQuery, EntityStringQuery {

    enum Key: String {
        case summary
    }

    var workflows: [WorkflowIdentifier] {
        get async {
            let settings = await Settings()
            let workflows = await settings.workflowsCache
            return workflows.map { id in
                return WorkflowIdentifier(repository: id.repositoryFullName,
                                          workflow: id.workflowId,
                                          branch: id.branch)
            }
        }
    }

    func entities(matching string: String) async throws -> [WorkflowIdentifier] {
        return await workflows
            .filter { workflowIdentifier in
                workflowIdentifier.repository.contains(string)
            }
    }


    func entities(for identifiers: [WorkflowIdentifier.ID]) async throws -> [WorkflowIdentifier] {
        return await workflows.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WorkflowIdentifier] {
        return await workflows
    }

    func defaultResult() async -> WorkflowIdentifier? {
        return nil
    }
}
