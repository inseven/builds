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

public enum OperationState: Codable {

    case unknown
    case queued
    case waiting
    case inProgress
    case success
    case failure
    case cancelled
    case skipped

    private static let order: [OperationState] = [
        .failure,
        .waiting,
        .inProgress,
        .queued,
        .cancelled,
        .skipped,
        .success,
        .unknown,
    ]

    private static let scores: [OperationState: Int] = order
        .enumerated()
        .reduce(into: [OperationState: Int]()) { partialResult, item in
            partialResult[item.element] = item.offset
        }

    public var score: Int {
        return Self.scores[self] ?? 100
    }

    public var isActive: Bool {
        return self == .inProgress
    }

    public var name: LocalizedStringKey {
        switch self {
        case .queued:
            return "Queued"
        case .waiting:
            return "Waiting"
        case .inProgress:
            return "In Progress"
        case .success:
            return "Succeeded"
        case .failure:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .skipped:
            return "Skipped"
        case .unknown:
            return "Unknown"
        }
    }

    public var color: Color {
        switch self {
        case .queued:
            return .yellow
        case .waiting:
            return .yellow
        case .inProgress:
            return .yellow
        case .success:
            return .green
        case .failure:
            return .red
        case .cancelled:
            return .red
        case .skipped:
            return .gray
        case .unknown:
            return .gray
        }
    }

    public var systemImage: String {
        switch self {
        case .queued:
            return "circle"
        case .waiting:
            return "clock"
        case .inProgress:
            return "circle.dashed"
        case .success:
            return "checkmark"
        case .failure:
            return "xmark"
        case .cancelled:
            return "exclamationmark.octagon"
        case .skipped:
            return "slash.circle"
        case .unknown:
            return "questionmark"
        }
    }

    public init(status: GitHub.Status?, conclusion: GitHub.Conclusion?) {
        switch status {
        case .queued:
            self = .queued
        case .waiting:
            self = .waiting
        case .inProgress:
            self = .inProgress
        case .completed:
            switch conclusion {
            case .success:
                self = .success
            case .failure:
                self = .failure
            case .cancelled:
                self = .cancelled
            case .skipped:
                self = .skipped
            case .none:
                self = .unknown
            }
        case .none:
            self = .unknown
        }
    }

}

extension Collection where Element == OperationState {

    public func sorted() -> [OperationState] {
        return sorted { $0.score < $1.score }
    }

}
