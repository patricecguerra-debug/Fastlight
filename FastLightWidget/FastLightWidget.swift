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
    func placeholder(in context: Context) -> FastLightEntry {
        FastLightEntry(date: Date(), fastingState: .fasting)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastLightEntry) -> Void) {
        let entry = FastLightEntry(date: Date(), fastingState: .fasting)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastLightEntry>) -> Void) {
        let schedule = FastingSchedule(eatingWindowStartHour: 12, eatingWindowEndHour: 20)
        let now = Date()
        let state = schedule.state(at: now)

        let entry = FastLightEntry(date: now, fastingState: state)

        // Refresh every hour on the hour
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: calendar.startOfHour(for: now))!
        let timeline = Timeline(entries: [entry], policy: .after(nextHour))
        completion(timeline)
    }
}

struct FastLightEntry: TimelineEntry {
    let date: Date
    let fastingState: FastingState
}

struct FastLightWidgetEntryView: View {
    var entry: FastLightEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.fastingState.isFasting ? "moon.stars.fill" : "sun.max.fill")
                .font(.title)
                .foregroundStyle(entry.fastingState.isFasting ? .green : .red)

            Text(entry.fastingState.isFasting ? "Fasting" : "Eating")
                .font(.headline)
                .fontWeight(.bold)
        }
        .containerBackground(.background, for: .widget)
    }
}