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

import Interact

@Observable
class SceneModel: Runnable {

    struct Settings: Codable {
        var columnVisibility: NavigationSplitViewVisibility = .automatic
        var sheet: SheetType?
        var previewURL: URL?
        var section: SectionIdentifier? = .all
    }

    enum SheetType: Identifiable, Codable {

        var id: String {
            switch self {
            case .add:
                return "add"
            case .settings:
                return "settings"
            case .logIn:
                return "log-in"
            case .view(let id):
                return "view-\(id)"
            }
        }

        case add
        case settings
        case logIn
        case view(WorkflowInstance.ID)
    }

    @MainActor var settings: Settings {
        didSet {
            applicationModel.settings.sceneSettings = settings
        }
    }

    @MainActor var selection = Set<WorkflowInstance.ID>()
    @MainActor var confirmation: Confirmable?

    private let applicationModel: ApplicationModel

    private var cancellables = Set<AnyCancellable>()

    @MainActor init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        self.settings = applicationModel.settings.sceneSettings
    }

    @MainActor var workflows: [WorkflowInstance] {
        switch settings.section {
        case .all:
            return applicationModel.results
        case .organization(let organization):
            return applicationModel.results.filter { $0.id.organization == organization }
        case .none:
            return []
        }
    }

    @MainActor func start() {
        applicationModel
            .$organizations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] organizations in
                guard let self else {
                    return
                }
                guard let section = settings.section,
                      case SectionIdentifier.organization(let organization) = section,
                      !organizations.contains(organization) else {
                    return
                }
                settings.section = .all
            }
            .store(in: &cancellables)
    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

    @MainActor func showSettings() {
        settings.sheet = .settings
    }

    @MainActor func logIn() {
#if os(macOS)
        applicationModel.logIn()
#else
        settings.sheet = .logIn
#endif
    }

    @MainActor func signOut() {
        confirmation = Confirmation(
            "Sign Out",
            message: "Signing out will remove Builds from your GitHub account and clear your favorites from iCloud.",
            actions: [
                ConfirmableAction("Sign Out", role: .destructive) {
                    await self.applicationModel.signOut(preserveFavorites: false)
                    self.settings.sheet = nil
                    self.settings.section = .all
                },
                ConfirmableAction("Sign Out and Keep Favorites") {
                    await self.applicationModel.signOut(preserveFavorites: true)
                    self.settings.sheet = nil
                    self.settings.section = .all
                },
            ])
    }

    @MainActor func manageWorkflows() {
#if os(iOS)
        settings.sheet = .add
#else
        Application.open(.manageWorkflows)
#endif
    }

}

extension SceneModel: PresentURLAction.Presenter {

    @MainActor func presentURL(_ url: URL) {
        if applicationModel.useInAppBrowser {
            settings.previewURL = url
        } else {
            Application.open(url)
        }
    }

}
