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

struct ActionStatus: Identifiable, Codable {

    var id: Action { action }

    let action: Action
    let workflowRun: GitHub.WorkflowRun?
    let annotations: [GitHub.Annotation]

    init(action: Action, workflowRun: GitHub.WorkflowRun?, annotations: [GitHub.Annotation] = []) {
        self.action = action
        self.workflowRun = workflowRun
        self.annotations = annotations
    }

}

enum SummaryState {

    case unknown
    case success
    case failure
    case inProgress

}

extension ActionStatus {

    var name: String {
        let name = "\(workflowRun?.name ?? String(action.workflowId))"
        guard let branch = action.branch else {
            return name
        }
        return "\(name) (\(branch))"
    }

    var state: SummaryState {

        guard let workflowRun = workflowRun else {
            return .unknown
        }

        switch workflowRun.status {
        case .queued:
            return .inProgress
        case .waiting:
            return .inProgress
        case .inProgress:
            return .inProgress
        case .completed:
            break
        }

        guard let conclusion = workflowRun.conclusion else {
            return .unknown
        }

        switch conclusion {
        case .success:
            return .success
        case .failure:
            return .failure
        case .cancelled:
            return .failure
        }

    }

    var statusColor: Color {
        switch self.state {
        case .unknown:
            return .gray
        case .success:
            return .green
        case .failure:
            return .red
        case .inProgress:
            return .yellow
        }
    }

    var lastRun: String {
        guard let createdAt = workflowRun?.createdAt else {
            return "Unknown"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

}
