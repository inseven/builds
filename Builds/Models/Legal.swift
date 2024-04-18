// Copyright (c) 2018-2023 InSeven Limited
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

import Foundation

import Diligence
import Interact
import SelectableCollectionView

public struct Legal {

    public static let contents = Contents(repository: "inseven/builds",
                                          copyright: "Copyright © 2021-2024 Jason Morley") {
        let subject = "Builds Support (\(Bundle.main.version ?? "Unknown Version"))"
        Action("Website", url: URL(string: "https://builds.jbmorley.co.uk")!)
        Action("Privacy Policy", url: URL(string: "https://builds.jbmorley.co.uk/privacy-policy")!)
        Action("GitHub", url: URL(string: "https://github.com/inseven/builds")!)
        Action("Support", url: URL(address: "support@jbmorley.co.uk", subject: subject)!)
    } acknowledgements: {
        Acknowledgements("Developers") {
            Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
        }
        Acknowledgements("Thanks") {
            Credit("Blake Merryman")
            Credit("Lukas Fittl")
            Credit("Mike Rhodes")
            Credit("Pavlos Vinieratos")
            Credit("Sara Frederixon")
            Credit("Sarah Barbour")
        }
    } licenses: {
        (.interact)
        (.selectableCollectionView)
        License("Builds", author: "Jason Morley", filename: "builds-license")
        License("Material Icons", author: "Google", filename: "material-icons-license")
        License("SwiftDraw", author: "Simon Whitty", filename: "swiftdraw-license")
    }

}
