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

import Foundation

public struct Summary: Codable, Equatable {

    public let status: OperationState.Summary  // TODO: Remove OperationState.Summary
    public let count: Int
    public let date: Date?
    public let details: [OperationState: Int]

    public init(status: OperationState.Summary = .unknown,
                count: Int = 0,
                date: Date? = nil,
                details: [OperationState: Int] = [:]) {
        self.status = status
        self.count = count
        self.date = date
        self.details = details
    }

    public init(workflowInstances: [WorkflowInstance]) {

        guard workflowInstances.count > 0 else {
            self.init()
            return
        }

        var status: OperationState.Summary = .success
        var details: [OperationState: Int] = [:]
        for result in workflowInstances {
            let count = details[result.operationState] ?? 0
            details[result.operationState] = count + 1
            switch result.summary {
            case .unknown:
                status = .unknown
                break
            case .success:  // We require 100% successes for success.
                continue
            case .skipped:  // Skipped builds don't represent failure.
                continue
            case .failure:  // We treat any failure as a global failure.
                status = .failure
                break
            case .inProgress:
                status = .inProgress
                break
            }
        }
        let date = workflowInstances.compactMap({ $0.createdAt }).max()

        self.init(status: status, count: workflowInstances.count, date: date, details: details)
    }

}
