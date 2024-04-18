//
//  Previews.swift
//  Builds
//
//  Created by Jason Barrie Morley on 18/04/2024.
//

import WidgetKit

import BuildsCore

#Preview(as: .systemSmall) {
    AllWorkflowsWidget()
} timeline: {
    AllWorkflowsTimeEntry(summary: Summary())
    AllWorkflowsTimeEntry(summary: Summary(status: .unknown, count: 12, date: .now))
    AllWorkflowsTimeEntry(summary: Summary(status: .inProgress, count: 12, date: .now))
    AllWorkflowsTimeEntry(summary: Summary(status: .success, count: 12, date: .now))
    AllWorkflowsTimeEntry(summary: Summary(status: .skipped, count: 12, date: .now))
    AllWorkflowsTimeEntry(summary: Summary(status: .failure, count: 34, date: .now.addingTimeInterval(-100)))
}
