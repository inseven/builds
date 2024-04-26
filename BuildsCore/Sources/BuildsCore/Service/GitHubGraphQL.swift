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

struct GitHubGraphQL {

    enum CheckConclusionState: String, Codable {
        case actionRequired = "ACTION_REQUIRED"
        case timedOut = "TIMED_OUT"
        case cancelled = "CANCELLED"
        case failure = "FAILURE"
        case success = "SUCCESS"
        case neutral = "NEUTRAL"
        case skipped = "SKIPPED"
        case startupFailure = "STARTUP_FAILURE"
        case stale = "STALE"
    }

    struct WorkflowRun: Identifiable, Codable {
        let id: String

        let createdAt: Date
        let updatedAt: Date
        let file: WorkflowRunFile
        let resourcePath: URL
        let checkSuite: CheckSuite
    }

    struct WorkflowRunFile: Identifiable, Codable {
        let id: String

        let path: String
    }

    struct CheckSuite: Identifiable, Codable {

        let id: String

        let conclusion: CheckConclusionState
        let commit: Commit
    }

    struct Commit: Identifiable, Codable {

        let id: String

        let oid: String
    }

}
