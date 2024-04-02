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

struct StatusImage: View {

    let status: GitHub.Status?
    let conclusion: GitHub.Conclusion?
    let size: CGSize?

    init(status: GitHub.Status?, conclusion: GitHub.Conclusion?, size: CGSize? = nil) {
        self.status = status
        self.conclusion = conclusion
        self.size = size
    }

    var systemImage: String {
        switch status {
        case .queued:
            return "clock.arrow.circlepath"
        case .waiting:
            return "clock"
        case .inProgress:
            return "circle.dashed"
        case .completed:
            switch conclusion {
            case .success:
                return "checkmark"
            case .failure:
                return "xmark"
            case .cancelled:
                return "exclamationmark.octagon"
            case .skipped:
                return "slash.circle"
            case .none:
                return "questionmark"
            }
        case .none:
            return "questionmark"
        }
    }

    var body: some View {
        if let size {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .rotates(status == .inProgress)
        } else {
            Image(systemName: systemImage)
                .rotates(status == .inProgress)
        }
    }

}
