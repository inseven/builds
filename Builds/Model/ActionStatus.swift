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

// TODO: let?
struct ActionStatus: Identifiable {

    var id: Action { action }

    var action: Action
    var workflowRun: GitHub.WorkflowRun?
    var annotations: [GitHub.Annotation]

    init(action: Action, workflowRun: GitHub.WorkflowRun?, annotations: [GitHub.Annotation] = []) {
        self.action = action
        self.workflowRun = workflowRun
        self.annotations = annotations
    }

}

extension ActionStatus {

    var name: String {
        let name = "\(workflowRun?.name ?? String(action.workflowId))"
        guard let branch = action.branch else {
            return name
        }
        return "\(name) (\(branch))"
    }

    var statusColor: Color {
        guard let workflowRun = workflowRun else {
            return .gray
        }

        switch workflowRun.status {
        case .queued:
            return .yellow
        case .waiting:
            return .yellow
        case .inProgress:
            return .orange
        case .completed:
            break
        }

        guard let conclusion = workflowRun.conclusion else {
            return .gray
        }

        switch conclusion {
        case .success:
            return .green
        case .failure:
            return .red
        case .cancelled:
            return .gray
        }
    }

    var lastRun: String {
        guard let createdAt = workflowRun?.createdAt else {
            return "Never"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

}
