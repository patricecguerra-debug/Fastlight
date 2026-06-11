import WidgetKit
import SwiftUI
import FastLightKit

struct FastLightWidget: Widget {
    let kind: String = "com.fastlight.app.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FastLightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fast Status")
        .description("See at a glance whether you're in your fasting window.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    // Use the 16:8 schedule as default for the widget
    let engine = FastLightEngine.sixteenEight

    func placeholder(in context: Context) -> FastLightEntry {
        FastLightEntry(date: Date(), status: .fasting)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastLightEntry) -> Void) {
        let entry = FastLightEntry(date: Date(), status: .fasting)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastLightEntry>) -> Void) {
        let now = Date()
        let status = engine.currentStatus()

        let entry = FastLightEntry(date: now, status: status)

        // Refresh just before the next transition to keep the widget accurate
        let refreshDate: Date
        if let nextTransition = engine.nextTransition() {
            // Refresh 1 minute before the transition so it flips on time
            refreshDate = nextTransition.addingTimeInterval(-60)
        } else {
            // Fallback: refresh hourly
            let calendar = Calendar.current
            refreshDate = calendar.date(byAdding: .hour, value: 1, to: calendar.startOfHour(for: now))!
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct FastLightEntry: TimelineEntry {
    let date: Date
    let status: WindowStatus
}

struct FastLightWidgetEntryView: View {
    var entry: FastLightEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.status.isFasting ? "moon.stars.fill" : "sun.max.fill")
                .font(.title)
                .foregroundStyle(entry.status.isFasting ? .green : .red)

            Text(entry.status.isFasting ? "Fasting" : "Eating")
                .font(.headline)
                .fontWeight(.bold)
        }
        .containerBackground(.background, for: .widget)
    }
}