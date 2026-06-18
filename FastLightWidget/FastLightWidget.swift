import WidgetKit
import SwiftUI
import FastLightKit

struct FastLightWidget: Widget {
    let kind: String = "com.fastlight.app.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleSelectionIntent.self,
            provider: Provider()
        ) { entry in
            FastLightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fast Status")
        .description("See at a glance whether you're in your fasting window.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: AppIntentTimelineProvider {
    // MARK: - Placeholder / Snapshot

    func placeholder(in context: Context) -> FastLightEntry {
        FastLightEntry(
            date: Date(),
            status: .fasting,
            schedule: FastingSchedule.fromPreset(.sixteenEight),
            preset: .sixteenEight
        )
    }

    func snapshot(for configuration: ScheduleSelectionIntent, in context: Context) async -> FastLightEntry {
        let preset = configuration.preset.fastLightPreset
        let schedule = FastingSchedule.fromPreset(preset)
        return FastLightEntry(
            date: Date(),
            status: .fasting,
            schedule: schedule,
            preset: configuration.preset
        )
    }

    // MARK: - Timeline

    func timeline(for configuration: ScheduleSelectionIntent, in context: Context) async -> Timeline<FastLightEntry> {
        let now = Date()
        let widgetPreset = configuration.preset
        let preset = widgetPreset.fastLightPreset
        let schedule = FastingSchedule.fromPreset(preset)
        let engine = FastLightEngine(schedule: schedule)
        let status = engine.currentStatus()

        // Persist the user's selection so the app stays in sync
        FastingSettingsStore.shared.selectedPreset = preset

        let entry = FastLightEntry(
            date: now,
            status: status,
            schedule: schedule,
            preset: widgetPreset
        )

        // Refresh 1 minute before the next state transition
        let refreshDate = schedule.nextRefreshDate()

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

// MARK: - Entry

struct FastLightEntry: TimelineEntry {
    let date: Date
    let status: WindowStatus
    let schedule: FastingSchedule
    let preset: WidgetSchedulePreset
}

// MARK: - Widget Views

struct FastLightWidgetEntryView: View {
    var entry: FastLightEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: Small Widget

    private var smallWidget: some View {
        VStack(spacing: 10) {
            Image(systemName: entry.status.isFasting ? "moon.stars.fill" : "sun.max.fill")
                .font(.system(size: 40))
                .symbolRenderingMode(.multicolor)
                .fontWeight(.bold)

            Text(entry.status.isFasting ? "Fasting" : "Eating")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(entry.schedule.label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(entry.status.isFasting ? Color.green.gradient : Color.red.gradient, for: .widget)
    }

    // MARK: Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Icon column
            Image(systemName: entry.status.isFasting ? "moon.stars.fill" : "sun.max.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)
                .fontWeight(.bold)

            // Info column
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.status.isFasting ? "Fasting" : "Eating Window")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(timeRemaining)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(entry.schedule.label)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(entry.status.isFasting ? Color.green.gradient : Color.red.gradient, for: .widget)
    }

    // MARK: Helpers

    private var timeRemaining: String {
        let now = entry.date
        let engine = FastLightEngine(schedule: entry.schedule)
        return engine.timeRemainingString(timeZone: .current)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    FastLightWidget()
} timeline: {
    FastLightEntry(date: Date(), status: .fasting, schedule: .fromPreset(.sixteenEight), preset: .sixteenEight)
    FastLightEntry(date: Date(), status: .eating, schedule: .fromPreset(.sixteenEight), preset: .sixteenEight)
}

#Preview(as: .systemMedium) {
    FastLightWidget()
} timeline: {
    FastLightEntry(date: Date(), status: .fasting, schedule: .fromPreset(.sixteenEight), preset: .sixteenEight)
    FastLightEntry(date: Date(), status: .eating, schedule: .fromPreset(.sixteenEight), preset: .sixteenEight)
}