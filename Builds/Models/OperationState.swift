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

struct OperationState {

    enum Summary {

        case unknown
        case success
        case failure
        case inProgress
        case skipped

        var color: Color {
            switch self {
            case .unknown:
                return .gray
            case .success:
                return .green
            case .failure:
                return .red
            case .inProgress:
                return .yellow
            case .skipped:
                return .gray
            }
        }

    }

    let status: GitHub.Status?
    let conclusion: GitHub.Conclusion?

    var isActive: Bool {
        return status == .inProgress
    }

    var name: LocalizedStringKey {
        switch status {
        case .queued:
            return "Queued"
        case .waiting:
            return "Waiting"
        case .inProgress:
            return "In Progress"
        case .completed:
            switch conclusion {
            case .success:
                return "Succeeded"
            case .failure:
                return "Failed"
            case .cancelled:
                return "Cancelled"
            case .skipped:
                return "Skipped"
            case .none:
                return "Unknown"
            }
        case .none:
            return "Unknown"
        }
    }

    var summary: Summary {
        switch status {
        case .queued, .waiting, .inProgress:
            return .inProgress
        case .completed:
            switch conclusion {
            case .success:
                return .success
            case .failure:
                return .failure
            case .cancelled:
                return .failure
            case .skipped:
                return .skipped
            case .none:
                return .unknown
            }
        case .none:
            return .unknown
        }
    }

    var systemImage: String {
        switch status {
        case .queued:
            return "clock.arrow.circlepath"
        case .waiting:
            return "clock"
        case .inProgress:
            return "circle.dashed"
        case .completed:
            switch conclusion {
            case .success:
                return "checkmark"
            case .failure:
                return "xmark"
            case .cancelled:
                return "exclamationmark.octagon"
            case .skipped:
                return "slash.circle"
            case .none:
                return "questionmark"
            }
        case .none:
            return "questionmark"
        }
    }

    init(status: GitHub.Status?, conclusion: GitHub.Conclusion?) {
        self.status = status
        self.conclusion = conclusion
    }

}
