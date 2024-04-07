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

import WidgetKit
import SwiftUI

import Interact

struct Provider: AppIntentTimelineProvider {

    enum Key: String {
        case summary
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let defaults = KeyedDefaults<Key>(defaults: UserDefaults(suiteName: "group.uk.co.jbmorley.builds")!)
        let summary: Summary?  = try? defaults.codable(forKey: .summary)

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, summary: summary, configuration: configuration)
        entries.append(entry)

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let summary: Summary?
    let configuration: ConfigurationAppIntent

    init(date: Date, summary: Summary? = nil, configuration: ConfigurationAppIntent) {
        self.date = date
        self.summary = summary
        self.configuration = configuration
    }
}

struct BuildsWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(systemName: entry.summary?.status.systemImage ?? "questionmark")
                    .imageScale(.large)
            }
            Spacer()
            Text("\(entry.summary?.count ?? 0) Workflows")
            if let date = entry.summary?.date {
                Text(date, format: .relative(presentation: .named))
                    .font(.subheadline)
                    .opacity(0.6)
            } else {
                Text("-")
                    .font(.subheadline)
                    .opacity(0.6)
            }
        }
        .foregroundColor(.black)
        .containerBackground(entry.summary?.status.color ?? .pink, for: .widget)
    }
}

struct BuildsWidget: Widget {
    let kind: String = "BuildsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BuildsWidgetEntryView(entry: entry)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    BuildsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
