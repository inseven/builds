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
import Interact

@main
struct BuildsApp: App {

    var applicationModel: ApplicationModel!

    @MainActor init() {
        applicationModel = ApplicationModel()
    }

    var body: some Scene {

        MainWindow()
            .commands {
                AccountCommands(applicationModel: applicationModel)
                LifecycleCommands(applicationModel: applicationModel)
            }
            .environmentObject(applicationModel)

#if os(macOS)

        SummaryWindow()
            .environmentObject(applicationModel)

        About(Legal.contents)

        WorkflowsWindow()
            .environmentObject(applicationModel)

#endif

    }
    
}

struct RepositoryDetails: Identifiable {

    var id: Int {
        repository.id
    }

    let repository: GitHub.Repository
    let workflows: [GitHub.Workflow]
    let branches: [GitHub.Branch]

}

class WorkflowsModel: ObservableObject, Runnable {

    @MainActor @Published var repositories: [RepositoryDetails]?
    @MainActor @Published var error: Error?

    let applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    @MainActor func start() {
        updateRepositories()
    }

    @MainActor func stop() {

    }

    func updateRepositories() {
        let client = applicationModel.client
        Task {
            do {
                let repositories = try await client
                    .repositories()
                    .compactMap { repository -> RepositoryDetails? in
                        guard !repository.archived else {
                            return nil
                        }
                        let workflows = try await client.workflows(for: repository)
                        guard workflows.count > 0 else {
                            return nil
                        }
                        let branches = try await client.branches(for: repository)
                        return RepositoryDetails(repository: repository,
                                                 workflows: workflows,
                                                 branches: branches)
                    }
                    .sorted { $0.repository.fullName.localizedStandardCompare($1.repository.fullName) == .orderedAscending }
                await MainActor.run {
                    self.repositories = repositories
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

}

struct ConcreteWorkflowDetails: Identifiable {

    var id: String {
        return "\(name)@\(branch)"
    }

    let name: String
    let branch: String

}

class WorkflowPickerModel: ObservableObject, Runnable {

    @Published var workflow: GitHub.Workflow?
    @Published var branch: GitHub.Branch?
    @MainActor @Published var actions: [ConcreteWorkflowDetails] = []

    private let applicationModel: ApplicationModel
    let repositoryDetails: RepositoryDetails
    private var cancellables = Set<AnyCancellable>()

    init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        self.repositoryDetails = repositoryDetails
        self.workflow = repositoryDetails.workflows.first
        self.branch = repositoryDetails.branches.first { repositoryDetails.repository.defaultBranch == $0.name }
    }

    @MainActor func start() {
        applicationModel
            .$actions
            .map { actions in
                return actions
                    .filter { action in
                        return action.repositoryFullName == self.repositoryDetails.repository.fullName
                    }
                    .map { action in
                        let workflow = self.repositoryDetails.workflows.first(where: { $0.id == action.workflowId })
                        return ConcreteWorkflowDetails(name: workflow?.name ?? String(action.workflowId),
                                                       branch: action.branch)
                    }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.actions, on: self)
            .store(in: &cancellables)
    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

    @MainActor func add() {
        guard let workflow = workflow,
              let branch = branch else {
            return
        }
        let action = Action(repositoryFullName: repositoryDetails.repository.fullName,
                            workflowId: workflow.id,
                            branch: branch.name)
        applicationModel.addAction(action)
    }

}

struct WorkflowPicker: View {

    @ObservedObject var applicationModel: ApplicationModel
    @StateObject var workflowPickerModel: WorkflowPickerModel

    init(applicationModel: ApplicationModel, repositoryDetails: RepositoryDetails) {
        self.applicationModel = applicationModel
        _workflowPickerModel = StateObject(wrappedValue: WorkflowPickerModel(applicationModel: applicationModel,
                                                                             repositoryDetails: repositoryDetails))
    }

    var body: some View {
        VStack {
            ForEach(workflowPickerModel.actions) { action in
                HStack {
                    Text(String(action.name))
                    Text("@")
                    Text(action.branch)
                    Spacer()
                }
                .padding(8)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            HStack {
                Picker("Workflow", selection: $workflowPickerModel.workflow) {
                    ForEach(workflowPickerModel.repositoryDetails.workflows) { workflow in
                        Text(workflow.name)
                            .tag(workflow as GitHub.Workflow?)
                    }
                }
                Picker("@", selection: $workflowPickerModel.branch) {
                    ForEach(workflowPickerModel.repositoryDetails.branches) { workflow in
                        Text(workflow.name)
                            .tag(workflow as GitHub.Branch?)
                    }
                }
                Button {
                    workflowPickerModel.add()
                } label: {
                    Text("Add")
                }
            }
            .padding(8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .runs(workflowPickerModel)
    }

}

struct WorkflowsContentView: View {

    @ObservedObject var applicationModel: ApplicationModel

    @StateObject var workflowsModel: WorkflowsModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _workflowsModel = StateObject(wrappedValue: WorkflowsModel(applicationModel: applicationModel))
    }

    var body: some View {
        VStack {
            if let repositories = workflowsModel.repositories {
                List {
                    VStack(alignment: .leading) {
                        ForEach(repositories) { repository in
                            Section {
                                WorkflowPicker(applicationModel: applicationModel, repositoryDetails: repository)
                            } header: {
                                Text(repository.repository.fullName)
                                    .font(.title)
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .runs(workflowsModel)
        .presents($workflowsModel.error)
    }

}

struct WorkflowsWindow: Scene {

    @EnvironmentObject var applicationModel: ApplicationModel

    static let id = "workflows"

    var body: some Scene {
        Window("Workflows", id: Self.id) {
            WorkflowsContentView(applicationModel: applicationModel)
        }

    }

}
