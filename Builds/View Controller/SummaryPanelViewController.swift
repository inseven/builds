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

#if os(macOS)

import Combine
import SceneKit

class SummaryPanelViewController: NSViewController {

    private let applicationModel: ApplicationModel
    private let scene: SCNScene
    private let green: SCNNode
    private let red: SCNNode
    private let silver: SCNNode
    private let whilte: SCNNode
    private let yellow: SCNNode

    private var selection: SCNNode? = nil

    @MainActor private var cancellables = Set<AnyCancellable>()

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel

        scene = SCNScene(named: "Scenes/Hypercasual.scn")!
        scene.background.contents = NSColor.clear

        green = scene.rootNode.childNode(withName: "green", recursively: true)!
        red = scene.rootNode.childNode(withName: "red", recursively: true)!
        silver = scene.rootNode.childNode(withName: "silver", recursively: true)!
        whilte = scene.rootNode.childNode(withName: "white", recursively: true)!
        yellow = scene.rootNode.childNode(withName: "yellow", recursively: true)!

        selection = whilte

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let view = SCNView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.scene = scene
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
        cameraNode.eulerAngles.x = 1.0 * CGFloat(-5.0 * .pi / 180.0)
        scene.rootNode.addChildNode(cameraNode)

        view.pointOfView = cameraNode

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Close", action: #selector(close), keyEquivalent: ""))
        view.menu = menu

        self.view.addSubview(view)
    }

    @objc func close() {
        view.window?.close()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        applicationModel
            .$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                guard let self else {
                    return
                }
                let newSelection: SCNNode
                switch summary?.operationState {
                case .unknown:
                    newSelection = silver
                case .success:
                    newSelection = green
                case .failure:
                    newSelection = red
                case .inProgress:
                    newSelection = yellow
                case .skipped:
                    newSelection = whilte
                case .none:
                    newSelection = silver
                case .queued:
                    newSelection = yellow
                case .waiting:
                    newSelection = yellow
                case .cancelled:
                    newSelection = red
                }
                guard newSelection != selection else {
                    return
                }
                newSelection.isHidden = false
                selection?.isHidden = true
                selection = newSelection
            }
            .store(in: &cancellables)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        cancellables.removeAll()
    }

}

#endif
