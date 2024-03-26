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

// TODO: Can I use the new observable stuff?
class SceneModel: ObservableObject, Runnable {

    struct Settings: Codable {

        var columnVisibility: NavigationSplitViewVisibility = .automatic
        var section: SectionIdentifier? = .all
        var isShowingInspector: Bool = false
        var selection = Set<WorkflowInstance.ID>()

    }

    enum SheetType: Identifiable {

        var id: Self {
            return self
        }

        case add
        case settings
        case logIn
    }

    @MainActor @Published var columnVisibility: NavigationSplitViewVisibility = .automatic {
        didSet {
            store.columnVisibility = columnVisibility
            // TODO: Write-through to a global set of scene store defaults.
        }
    }

    @MainActor @Published var section: SectionIdentifier? {
        didSet {
            store.section = section
        }
    }
    @MainActor @Binding var store: Settings
    @MainActor @Published var sheet: SheetType?

    @MainActor @Published var isShowingInspector: Bool {
        didSet {
            store.isShowingInspector = isShowingInspector
            if !isShowingInspector {
#if os(iOS)
                selection = []
#endif
            }
        }
    }
    
    @MainActor @Published var selection: Set<WorkflowInstance.ID> {
        didSet {
            store.selection = selection
        }
    }

    @MainActor @Published var confirmation: Confirmable?

    private let applicationModel: ApplicationModel

    private var cancellables = Set<AnyCancellable>()

    @MainActor init(applicationModel: ApplicationModel, store: Binding<Settings>) {
        // The scene storage lifecycle is distinctly different betwene macOS and iOS.
        // On iOS the scene storage is deserialized _before_ the view is created. On macOS, it appears to be
        // loaded and applied _after_ the view structure is created. This is fucking bonkers and means our model is
        // created with out of date data and there's no obvious way to broadcast that into the client for a reload.
        self.applicationModel = applicationModel
        _store = store
        self.columnVisibility = store.wrappedValue.columnVisibility
        self.section = store.wrappedValue.section
        self.isShowingInspector = store.wrappedValue.isShowingInspector
        self.selection = store.wrappedValue.selection
    }

    @MainActor func start() {
        applicationModel
            .$organizations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] organizations in
                guard let self else {
                    return
                }
                guard let section = self.section,
                      case SectionIdentifier.organization(let organization) = section,
                      !organizations.contains(organization) else {
                    return
                }
                self.section = nil
            }
            .store(in: &cancellables)
    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

    @MainActor func showSettings() {
        isShowingInspector = false
        sheet = .settings
    }

    @MainActor func showInspector() {
        isShowingInspector = true
    }

    @MainActor func hideInspector() {
#if os(iOS)
        selection = []
#endif
        isShowingInspector = false
    }

    @MainActor func toggleInspector() {
        if isShowingInspector {
            hideInspector()
        } else {
            showInspector()
        }
    }


    @MainActor func logIn() {
#if os(macOS)
        applicationModel.logIn()
#else
        sheet = .logIn
#endif
    }

    @MainActor func signOut() async {
        confirmation = Confirmation(
            "Sign Out",
            message: "Signing out will remove Builds from your GitHub account and clear your favorites from iCloud.",
            actions: [
                ConfirmableAction("Sign Out", role: .destructive) {
                    await self.applicationModel.signOut(preserveFavorites: false)
                    self.sheet = nil
                    self.section = .all
                },
                ConfirmableAction("Sign Out and Keep Favorites") {
                    await self.applicationModel.signOut(preserveFavorites: true)
                    self.sheet = nil
                    self.section = .all
                },
            ])
    }

    @MainActor func manageWorkflows() {
#if os(iOS)
        isShowingInspector = false
        sheet = .add
#else
        Application.open(.manageWorkflows)
#endif
    }

}
