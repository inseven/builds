//
//  ContentView.swift
//  Status
//
//  Created by Jason Barrie Morley on 31/03/2022.
//

import SwiftUI

// TODO: Rename GitHub to GitHubAPI

extension ActionStatus {

    var name: String {
        let name = "\(workflowRun?.name ?? String(action.workflowId))"
        guard let branch = action.branch else {
            return name
        }
        return "\(name) (\(branch))"
    }

    var statusColor: Color {
        guard let workflowRun = workflowRun else {
            return Color(UIColor.systemGray)
        }
        if workflowRun.status == .inProgress {
            return Color(uiColor: .systemOrange)
        }
        guard let conclusion = workflowRun.conclusion else {
            return Color(UIColor.systemGray)
        }
        switch conclusion {
        case .success:
            return Color(UIColor.systemGreen)
        case .failure:
            return Color(UIColor.systemRed)
        }
    }

    var lastRun: String {
        guard let createdAt = workflowRun?.createdAt else {
            return "Never"
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }

}

struct ContentView: View {

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case authenticate
        case add
        case settings
    }

    @State var sheet: SheetType?

    @EnvironmentObject var manager: Manager

    var body: some View {
        NavigationView {
            VStack {
                switch manager.client.state {
                case .authorized:
                    SummaryView()
                case .unauthorized:
                    Button {
                        sheet = .authenticate
                    } label: {
                        Text("Authenticate")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        sheet = .settings
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

        }
        .sheet(item: $sheet, content: { sheet in
            switch sheet {
            case .authenticate:
                AuthenticationView(client: manager.client) { result in
                    dispatchPrecondition(condition: .onQueue(.main))
                    switch result {
                    case .success:
                        print("AUTHENTICATED!")
                    case .failure(let error):
                        print("FAILED WITH ERROR \(error)")
                    }
                    self.sheet = nil
                }
            case .add:
                NavigationView {
                    ActionWizard()
                }
            case .settings:
                NavigationView {
                    SettingsView()
                }
            }
        })
    }
}
