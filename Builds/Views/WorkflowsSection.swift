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

struct WorkflowsSection: View {

    @ObservedObject var applicationModel: ApplicationModel
    @ObservedObject var sceneModel: SceneModel

    let section: SectionIdentifier

    var workflows: [WorkflowInstance] {
        switch section {
        case .all:
            return applicationModel.results
        case .organization(let organization):
            return applicationModel.results.filter { $0.id.organization == organization }
        }
    }

    var body: some View {
        VStack {
            if applicationModel.isAuthorized {
                if applicationModel.results.count > 0 {
                    WorkflowsView(workflows: workflows)
                } else {
                    ContentUnavailableView {
                        Text("No Workflows")
                    } description: {
                        Text("Select workflows to view their statuses.")
                    } actions: {
                        Button {
                            sceneModel.manageWorkflows()
                        } label: {
                            Text("Manage Workflows")
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Text("Logged Out")
                } description: {
                    Text("Log in to view your GitHub Actions workflows.")
                } actions: {
                    Button {
                        applicationModel.logIn()
                    } label: {
                        Text("Log In")
                    }
                }
            }
        }
        .navigationTitle(section.title)
        .toolbarTitleDisplayMode(.inline)
    }

}
