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

struct Sidebar: View {

    @ObservedObject var applicationModel: ApplicationModel
    @ObservedObject var sceneModel: SceneModel

    var body: some View {
        List(selection: $sceneModel.section) {
            Section {
                let identifier = SectionIdentifier.all
                NavigationLink(value: identifier) {
                    Text(identifier.title)
                        .tag(identifier)
                }
            }
            if applicationModel.organizations.count > 0 {
                Section {
                    ForEach(applicationModel.organizations, id: \.self) { organization in
                        let identifier = SectionIdentifier.organization(organization)
                        NavigationLink(value: identifier) {
                            Text(identifier.title)
                                .tag(identifier)
                        }
                    }
                } header: {
                    Text("Organizations")
                }
            }
        }
        .frame(minWidth: 200)
        .navigationTitle("Builds")
        .refreshable {
            await applicationModel.refresh()
        }
    }

}
