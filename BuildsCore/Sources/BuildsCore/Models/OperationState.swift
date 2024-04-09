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

    public enum Summary: Codable {

        case unknown
        case success
        case failure
        case inProgress
        case skipped

        public var color: Color {
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

        public var systemImage: String {
            switch self {
            case .unknown:
                return "questionmark"
            case .success:
                return "checkmark"
            case .failure:
                return "xmark"
            case .inProgress:
                return "circle.dashed"
            case .skipped:
                return "slash.circle"
            }
        }

    }

    case unknown
    case queued
    case waiting
    case inProgress
    case success
    case failure
    case cancelled
    case skipped

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

    public var summary: Summary {
        switch self {
        case .queued, .waiting, .inProgress:
            return .inProgress
        case .success:
            return .success
        case .failure:
            return .failure
        case .cancelled:
            return .failure
        case .skipped:
            return .skipped
        case .unknown:
            return .unknown
        }
    }

    public var systemImage: String {
        switch self {
        case .queued:
            return "clock.arrow.circlepath"
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
