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

import Combine
import SwiftUI

import Diligence

import BuildsCore

extension GitHub.Repository {

    // TODO: Is there an actual property for this??
    public var organization: String {
        return String(full_name.split(separator: "/").first ?? "?")
    }

}

@Observable
class AddRepositoriesModel {

    let applicationModel: ApplicationModel

    @MainActor var organizations: [String: [GitHub.Repository]] = [:]
    @MainActor var error: Error? = nil

    init(applicationModel: ApplicationModel) {
        // TODO: Double check if this is run by default?
        self.applicationModel = applicationModel
    }

    func update() async {
        do {
            let repositories = try await applicationModel.client.repositories(scope: .user)
                .filter{ !$0.archived }
                .reduce(into: [String: [GitHub.Repository]]()) { partialResult, repository in
                    let organization = repository.organization
                    let repositories = partialResult[organization] ?? []
                    partialResult[organization] = repositories + [repository]
                }
            await MainActor.run {
                self.organizations = repositories
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

}

struct BranchSection: View {

    @State var isExpanded: Bool = false

    let applicationModel: ApplicationModel
    let repository: GitHub.Repository
    let branch: GitHub.Branch
    let workflows: [GitHub.Workflow]

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(workflows) { workflow in
                HStack {
                    Text(workflow.name)
                    Spacer()
                    Toggle("", isOn: Binding.constant(true))
                }
                .tag("\(branch.id):\(workflow.id)")
            }
        } label: {
            Label {
                Text(branch.name)
                    .bold(branch.name == repository.default_branch)
            } icon: {
                Image(systemName: "play")
            }
        }
    }

}

struct RepositorySection: View {

    @State var isExpanded: Bool = false
    @State var branches: [GitHub.Branch] = []
    @State var workflows: [GitHub.Workflow] = []

    let applicationModel: ApplicationModel
    let repository: GitHub.Repository

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(branches) { branch in
                Text(branch.name)
                    .tag(branch.id)
//                BranchSection(applicationModel: applicationModel,
//                              repository: repository,
//                              branch: branch,
//                              workflows: workflows)
//                    .tag(branch.id)
            }
        } label: {
            Label {
                HStack {
                    Text(repository.name)
                    Spacer()
                    if branches.isEmpty {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            } icon: {
                Image(systemName: "cylinder")
            }
        }
        .task {
            let branches = ((try? await applicationModel.client.branches(for: repository)) ?? [])
                .sorted {
                    let defaultScore0 = repository.default_branch == $0.id ? 0 : 1
                    let defaultScore1 = repository.default_branch == $1.id ? 0 : 1
                    if defaultScore0 != defaultScore1 {
                        return defaultScore0 < defaultScore1
                    }
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            await MainActor.run {
                self.branches = branches
            }
        }
        .task {
            let workflows = (try? await applicationModel.client.workflows(for: repository)) ?? []
            await MainActor.run {
                self.workflows = workflows
            }
        }
    }

}

struct OrganizationSection: View {

    @State var isExpanded: Bool = false
    @State var repositories: [GitHub.Repository] = []

    let applicationModel: ApplicationModel
    let organization: GitHub.Organization

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(repositories) { repository in
                RepositorySection(applicationModel: applicationModel, repository: repository)
                    .tag(String(repository.id))
            }
        } label: {
            Label {
                Text(organization.name ?? organization.login)
            } icon: {
                Image(systemName: "building.2")
                    .imageScale(.small)
            }
        }
        .task {
            let repositories = ((try? await applicationModel.client.repositories(scope: organization)) ?? [])
                .sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            await MainActor.run {
                self.repositories = repositories
            }
        }
    }

}

struct AddRepositories: View {

    @State var selection: String?
    @State var model: AddRepositoriesModel

    @State var organizations: [GitHub.Organization] = []

    let applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _model = State(initialValue: AddRepositoriesModel(applicationModel: applicationModel))
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(organizations) { organization in
                OrganizationSection(applicationModel: applicationModel, organization: organization)
                    .tag(String(organization.id))
            }
        }
        .task {
            let organizations = (try? await applicationModel.client.organizations()) ?? []
            await MainActor.run {
                self.organizations = organizations
            }
        }
    }

}

@main
struct BuildsApp: App {

    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #else
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    @MainActor init() {
    }

    var body: some Scene {

        MainWindow()
            .commands {
                WorkflowCommands()
                AccountCommands(applicationModel: appDelegate.applicationModel)
                LifecycleCommands(applicationModel: appDelegate.applicationModel)
                InspectorCommands()
#if DEBUG
                SummaryCommands(applicationModel: appDelegate.applicationModel)
#endif
            }
            .environmentObject(appDelegate.applicationModel)

#if os(macOS)

        About(Legal.contents)

        WorkflowsWindow()
            .environmentObject(appDelegate.applicationModel)

        InfoWindow()
            .environmentObject(appDelegate.applicationModel)

        Window("Add Repositories", id: "add-repositories") {
            AddRepositories(applicationModel: appDelegate.applicationModel)
        }

#endif

    }
    
}
