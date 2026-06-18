import SwiftUI
import FastLightKit

struct ContentView: View {
    @State private var selectedPreset: FastingSchedule.Preset = .sixteenEight
    @State private var currentTime = Date()
    @State private var isPulsing = false

    private let store = FastingSettingsStore.shared

    private var engine: FastLightEngine {
        FastLightEngine(schedule: selectedPreset.schedule)
    }

    private var status: WindowStatus {
        engine.currentStatus()
    }

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // MARK: Brand Header
                brandHeader

                // MARK: Hero Status
                heroStatusCard
                    .padding(.horizontal)

                // MARK: Schedule Picker
                scheduleSection
                    .padding(.horizontal)

                // MARK: Day Timeline
                dayTimeline
                    .padding(.horizontal)

                // MARK: Details
                detailsSection
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .onReceive(timer) { time in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTime = time
            }
        }
        .onAppear {
            selectedPreset = store.selectedPreset
            // Start pulsing animation after a brief delay
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.3)) {
                isPulsing = true
            }
        }
        .onChange(of: selectedPreset) { _, newPreset in
            store.selectedPreset = newPreset
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 34))
                .foregroundStyle(.indigo)
                .symbolEffect(.breathe, value: isPulsing)

            Text("FastLight")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Hero Status Card

    private var heroStatusCard: some View {
        VStack(spacing: 20) {
            // Large pulsing status indicator
            ZStack {
                // Outer glow
                Circle()
                    .fill(status.isFasting ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.15 : 0.95)

                // Inner circle
                Circle()
                    .fill(status.isFasting ? Color.green : Color.red)
                    .frame(width: 100, height: 100)
                    .shadow(color: (status.isFasting ? Color.green : Color.red).opacity(0.4),
                            radius: isPulsing ? 20 : 10)

                // Icon
                Image(systemName: status.isFasting ? "moon.stars.fill" : "sun.max.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.multicolor)
            }
            .animation(.easeInOut(duration: 0.5), value: status)

            // Status text
            Text(status.isFasting ? "Fasting" : "Eating Window")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(status.isFasting ? Color.green : Color.red)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: status)

            // Time remaining
            Text(timeRemaining)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Schedule", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.indigo)

            // Picker row
            HStack {
                Text("Fasting plan")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Schedule", selection: $selectedPreset) {
                    ForEach(FastingSchedule.Preset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .tint(.indigo)
            }

            Divider()

            // Fast / Eat breakdown
            let schedule = selectedPreset.schedule
            HStack(spacing: 0) {
                // Fasting block
                Label {
                    Text("\(schedule.fastingWindowDurationHours)h fast")
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.indigo)
                }
                .font(.subheadline)

                Spacer()

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Eating block
                Label {
                    Text("\(schedule.eatingWindowDurationHours)h eat")
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Day Timeline

    private var dayTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Timeline", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.indigo)

            let schedule = selectedPreset.schedule
            let startHour = schedule.eatingWindowStartHour
            let endHour = schedule.eatingWindowEndHour

            // 24-hour bar
            VStack(spacing: 8) {
                // Timeline bar
                GeometryReader { geo in
                    let width = geo.size.width
                    let totalHours: CGFloat = 24
                    let hourWidth = width / totalHours

                    ZStack(alignment: .leading) {
                        // Full bar background
                        Capsule()
                            .fill(.indigo.opacity(0.12))
                            .frame(height: 28)

                        // Eating window highlight
                        let eatStartX = CGFloat(startHour) * hourWidth
                        let eatWidth: CGFloat
                        if endHour > startHour {
                            eatWidth = CGFloat(endHour - startHour) * hourWidth
                        } else {
                            // Wraps past midnight
                            eatWidth = (CGFloat(24 - startHour) + CGFloat(endHour)) * hourWidth
                        }

                        Capsule()
                            .fill(Color.orange.gradient)
                            .frame(width: eatWidth, height: 28)
                            .offset(x: eatStartX)
                    }
                }
                .frame(height: 28)

                // Hour labels
                HStack {
                    Text(schedule.timeRangeString)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fontWeight(.medium)

                    Spacer()

                    Text("Eating window")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.indigo)

            let schedule = selectedPreset.schedule
            VStack(spacing: 10) {
                DetailRow(label: "Eating window", value: schedule.timeRangeString)
                DetailRow(label: "Next change",
                          value: engine.nextTransition().formatted(date: .omitted, time: .shortened))
                DetailRow(label: "Schedule",
                          value: "\(schedule.fastingWindowDurationHours)h fasting / \(schedule.eatingWindowDurationHours)h eating")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var timeRemaining: String {
        let now = currentTime
        let engine = FastLightEngine(schedule: selectedPreset.schedule)
        return engine.timeRemainingString(timeZone: .current)
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
                .font(.subheadline)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ContentView()
}