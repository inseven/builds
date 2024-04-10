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

extension GitHub.Annotation: Identifiable {

    public var id: String {
        return "\(path):\(start_line):\(end_line):\(start_column ?? -1):\(end_column ?? -1)"
    }

}

public struct WorkflowResult: Codable, Hashable {

    public struct Annotation: Codable, Identifiable, Hashable {

        public var id: GitHub.Annotation.ID {
            return annotation.id
        }

        public let jobId: GitHub.WorkflowJob.ID
        public let annotation: GitHub.Annotation
    }

    public let workflowRun: GitHub.WorkflowRun
    public let jobs: [GitHub.WorkflowJob]
    public let annotations: [Annotation]

    public init(workflowRun: GitHub.WorkflowRun,
                jobs: [GitHub.WorkflowJob],
                annotations: [Annotation]) {
        self.workflowRun = workflowRun
        self.jobs = jobs
        self.annotations = annotations
    }

    public func job(for annotation: Annotation) -> GitHub.WorkflowJob? {
        return jobs.first {
            return $0.id == annotation.jobId
        }
    }

}