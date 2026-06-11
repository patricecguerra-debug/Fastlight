import SwiftUI
import FastLightKit

struct ContentView: View {
    @State private var selectedPreset: FastingSchedule.Preset = .sixteenEight
    @State private var currentTime = Date()

    private var engine: FastLightEngine {
        FastLightEngine(schedule: selectedPreset.schedule)
    }

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)

                Text("FastLight")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            // Status Card
            statusCard
                .padding(.horizontal)

            // Schedule Preset Picker
            presetPicker
                .padding(.horizontal)

            // Details
            detailsSection
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 60)
        .onReceive(timer) { time in
            currentTime = time
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        let status = engine.currentStatus()
        let detail = engine.detailedStatusDescription()

        return VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(status.isFasting ? Color.green : Color.red)
                    .frame(width: 20, height: 20)

                Text(status.isFasting ? "You are fasting" : "Eating window")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Preset Picker

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)

            Picker("Fasting Schedule", selection: $selectedPreset) {
                ForEach(FastingSchedule.Preset.allCases, id: \.self) { preset in
                    VStack(alignment: .leading) {
                        Text(preset.displayName).tag(preset)
                    }
                }
            }
            .pickerStyle(.menu)
            .tint(.indigo)

            // Schedule info
            let schedule = selectedPreset.schedule
            HStack {
                Label("\(schedule.fastingWindowDurationHours)h fast", systemImage: "moon.zzz.fill")
                    .foregroundStyle(.indigo)
                Spacer()
                Label("\(schedule.eatingWindowDurationHours)h eat", systemImage: "sun.max.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            let schedule = selectedPreset.schedule
            DetailRow(label: "Eating window",
                      value: "\(schedule.eatingWindowStartHour):00 – \(schedule.eatingWindowEndHour):00")

            if let nextTransition = engine.nextTransition() {
                DetailRow(label: "Next change",
                          value: nextTransition.formatted(date: .omitted, time: .shortened))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    ContentView()
}