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
    private let greenCat: SCNNode
    private let purpleCat: SCNNode
    private let tealCat: SCNNode
    private let whiteCat: SCNNode
    private let orangeCat: SCNNode

    private var selection: SCNNode? = nil

    @MainActor private var cancellables = Set<AnyCancellable>()

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel

        scene = SCNScene(named: "builds-resources/Cats.scn")!
        scene.background.contents = NSColor.clear

        greenCat = scene.rootNode.childNode(withName: "green", recursively: true)!
        purpleCat = scene.rootNode.childNode(withName: "purple", recursively: true)!
        tealCat = scene.rootNode.childNode(withName: "teal", recursively: true)!
        whiteCat = scene.rootNode.childNode(withName: "white", recursively: true)!
        orangeCat = scene.rootNode.childNode(withName: "orange", recursively: true)!

        selection = whiteCat

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

        self.view.addSubview(view)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        applicationModel
            .$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaryState in
                guard let self else {
                    return
                }
                let newSelection: SCNNode
                switch summaryState {
                case .unknown:
                    newSelection = whiteCat
                case .success:
                    newSelection = greenCat
                case .failure:
                    newSelection = purpleCat
                case .inProgress:
                    newSelection = orangeCat
                case .skipped:
                    newSelection = whiteCat
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
