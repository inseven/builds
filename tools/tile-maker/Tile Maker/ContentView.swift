//
//  ContentView.swift
//  Tile Maker
//
//  Created by Jason Barrie Morley on 03/04/2024.
//

import SwiftUI

struct Pattern: View {

    static let spacing = 32.0

    static let symbols = [
        "clock",
        "circle.dashed",
        "checkmark",
        "exclamationmark.triangle",
        "exclamationmark.octagon",
    ]

    var body: some View {
        HStack(spacing: Self.spacing) {
            ForEach(0..<6) { _ in
                VStack(spacing: Self.spacing) {
                    ForEach(0..<6) { _ in
                        Image(systemName: Self.symbols.randomElement()!)
                    }
                }
            }
            .imageScale(.large)
            .foregroundColor(.white)
        }
        .padding(Self.spacing / 2)
        .background(.green)
    }

}

class UnityScaleWindow: NSWindow {

    override var backingScaleFactor: CGFloat {
        return 1.0
    }

}

extension View {

    func snapshot() -> Data? {
        let controller = NSHostingController(rootView: self)
        let targetSize = controller.view.intrinsicContentSize
        let contentRect = NSRect(origin: .zero, size: targetSize)
        let window = UnityScaleWindow(contentRect: contentRect,
                                      styleMask: [.borderless],
                                      backing: .buffered,
                                      defer: false)
        window.contentView = controller.view
        guard let bitmapRep = controller.view.bitmapImageRepForCachingDisplay(in: contentRect) else {
            return nil
        }
        controller.view.cacheDisplay(in: contentRect, to: bitmapRep)
        let image = NSImage(size: bitmapRep.size)
        image.addRepresentation(bitmapRep)

        guard let tiffRepresentation = image.tiffRepresentation else {
            return nil
        }
        let imageRep = NSBitmapImageRep(data: tiffRepresentation)
        let pngData = imageRep?.representation(using: .png, properties: [:])
        return pngData
    }

}

struct ImageData: Transferable {

    let pngData: Data

    public static var transferRepresentation: some TransferRepresentation {

        DataRepresentation(exportedContentType: .png) { image in
            return image.pngData
        }
    }

}

//extension UIImage: Transferable {
//
//    public static var transferRepresentation: some TransferRepresentation {
//
//        DataRepresentation(exportedContentType: .png) { image in
//            if let pngData = image.pngData() {
//                return pngData
//            } else {
//                // Handle the case where UIImage could not be converted to png.
//                throw ConversionError.failedToConvertToPNG
//            }
//        }
//    }
//
//    enum ConversionError: Error {
//        case failedToConvertToPNG
//    }
//}

extension NSImage {
    func pngRepresentation() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

struct ContentView: View {

    @State var export: ImageData?

    var isPresented: Binding<Bool> {
        return Binding {
            return export != nil
        } set: { newValue in
            if !newValue {
                export = nil
            }
        }
    }

    var body: some View {
        VStack {
            Pattern()
            Button {
                let renderer = ImageRenderer(content: Pattern())
                renderer.scale = 2
                guard let image = renderer.nsImage else {
                    return
                }
                guard let data = image.pngRepresentation() else {
                    return
                }
//                guard let data = Pattern().snapshot() else {
//                    return
//                }
                self.export = ImageData(pngData: data)
            } label: {
                Text("Save")
            }
            .fileExporter(isPresented: isPresented, item: export) { result in
                print(result)
            }
        }
    }
}

#Preview {
    ContentView()
}
