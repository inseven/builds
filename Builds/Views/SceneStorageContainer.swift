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

class Serializable<Content: Codable>: RawRepresentable, ObservableObject {

    @Published var content: Content?

    var rawValue: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(content)
        return String(data: data, encoding: .utf8)!
    }

    init(_ content: Content?) {
        self.content = content
    }

    required init?(rawValue: String) {
        let decoder = JSONDecoder()
        guard let data = rawValue.data(using: .utf8),
              let content = try? decoder.decode(Content.self, from: data) else {
            return
        }
        self.content = content
    }

}

// This thing works around the [inferred] different scene storage lifecycle on macOS and iOS.
// iOS seems to work the way one might expect (SceneStorage is loaded by the time the body is constructed), but on macOS
// scene storage is loaded lazily meaning that we get an initial value when we create our body. This would work just
// fine if there weren't use-cases where we wanted to manipulate stored data in a model. Unfortunaetly, we do.
// This wrapper is set up with an optional to serve as a marker to indicate whether the data has been read and
// only sends the data through if it's non-nil.
//
// When testing this code there are some important things to remember about the lifecycle of SceneStorage:
//
// - SceneStorage is only written on background events; this makes some sense on iOS, but doesn't seem to make any sense
//   on macOS when you might quit the app having made changes to the window state and expect it to be restored in the
//   state you left it.
//
// The challenge of things not being written to disk in a timely fashion on macOS sucks. I think it might be possible to
// work around this by simply injecting a UUID into scene storage and then using user defautls or something else to
// actually store state on update.
//
// OK. The issue on macOS is that it's created with one value and restored to a different one. Right now, I can't seem
// to think of any way to disambiguate these two states? It also seems to be unique to macOS. OK. iPad OS does what we'd
// expect here and I think is therefore practical to use. So how do we fudge this on macOS?

#if os(macOS)

struct SceneStorageContainer<Settings: Codable, Content: View>: View {

    @State var windowIdenitifier: String?

    let constructor: () -> Settings
    let content: (Binding<Settings>) -> Content

    init(constructor: @escaping () -> Settings, @ViewBuilder content: @escaping (Binding<Settings>) -> Content) {
        self.constructor = constructor
        self.content = content
    }

    var body: some View {
        VStack {
            if let windowIdenitifier {

                let binding = Binding(get: {
                    let decoder = JSONDecoder()
                    guard let json = UserDefaults().string(forKey: windowIdenitifier),
                          let data = json.data(using: .utf8),
                          let value = try? decoder.decode(Settings.self, from: data)
                    else {
                        return constructor()
                    }
                    return value
                }, set: { (content: Settings) in
                    let encoder = JSONEncoder()
                    guard let data = try? encoder.encode(content),
                          let json = String(data: data, encoding: .utf8) else {
                        return
                    }
                    UserDefaults().set(json, forKey: windowIdenitifier)
                    UserDefaults().synchronize()
                })

                content(binding)

            } else {
                ProgressView()
            }
        }
        .onDisappear {
            guard let windowIdenitifier else {
                return
            }
            print("Deleting settings for window with identifier \(windowIdenitifier)...")
            UserDefaults().removeObject(forKey: windowIdenitifier)
            UserDefaults().synchronize()
        }
        .hookWindow { window in
            print("Hooking window with identifier \(window.identifier?.rawValue ?? "nil")...")
            windowIdenitifier = window.identifier?.rawValue
        }
    }

}

#else

struct SceneStorageContainer<Settings: Codable, Content: View>: View {

    @SceneStorage("somekey") var container: Serializable<Settings> = Serializable(nil)

    let constructor: () -> Settings
    let content: (Binding<Settings>) -> Content

    init(constructor: @escaping () -> Settings, @ViewBuilder content: @escaping (Binding<Settings>) -> Content) {
        self.constructor = constructor
        self.content = content
    }

    var body: some View {

        let binding = Binding {
            return container.content ?? constructor()
        } set: { settings in
            container = Serializable(settings)
        }

        content(binding)
    }

}

#endif
