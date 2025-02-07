// Copyright (c) 2021-2025 Jason Morley
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

public struct Job: Identifiable, Codable, Hashable {

    public var color: Color {
        return operationState.color
    }

    public let id: Int
    public let name: String

    public let startedAt: Date?
    public let completedAt: Date?

    public let operationState: OperationState

    public let url: URL
}

extension Job {

    init(_ workflowJob: GitHub.WorkflowJob) {

        self.id = workflowJob.id
        self.name = workflowJob.name

        self.startedAt = workflowJob.started_at
        self.completedAt = workflowJob.completed_at

        self.operationState = OperationState(status: workflowJob.status, conclusion: workflowJob.conclusion)

        self.url = workflowJob.html_url
    }

}
