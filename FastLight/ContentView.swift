import SwiftUI
import FastLightKit

struct ContentView: View {
    @State private var selectedPreset: FastingSchedule.Preset = .sixteenEight
    @State private var currentTime = Date()
    @State private var isPulsing = false
    @State private var showPaywall = false
    @StateObject private var premiumManager = PremiumManager.shared

    private let store = FastingSettingsStore.shared

    private var engine: FastLightEngine {
        FastLightEngine(schedule: selectedPreset.schedule)
    }

    private var status: WindowStatus {
        engine.currentStatus()
    }

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    brandHeader

                    heroStatusCard
                        .padding(.horizontal)

                    scheduleSection
                        .padding(.horizontal)

                    dayTimeline
                        .padding(.horizontal)

                    streakSection
                        .padding(.horizontal)

                    detailsSection
                        .padding(.horizontal)

                    if premiumManager.isPremium {
                        restoreButton
                            .padding(.horizontal)
                    } else {
                        premiumCTA
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $showPaywall) {
                PaywallView()
            }
            .onReceive(timer) { time in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentTime = time
                }
            }
            .onAppear {
                selectedPreset = store.selectedPreset
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.3)) {
                    isPulsing = true
                }
            }
            .onChange(of: selectedPreset) { _, newPreset in
                store.selectedPreset = newPreset
            }
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundStyle(.indigo)
                .symbolEffect(.breathe, value: isPulsing)

            Text("FastLight")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Spacer()

            if premiumManager.isPremium {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.yellow)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("Premium")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.indigo.gradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Hero Status Card

    private var heroStatusCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(status.isFasting ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.15 : 0.95)

                Circle()
                    .fill(status.isFasting ? Color.green : Color.red)
                    .frame(width: 100, height: 100)
                    .shadow(color: (status.isFasting ? Color.green : Color.red).opacity(0.4),
                            radius: isPulsing ? 20 : 10)

                Image(systemName: status.isFasting ? "moon.stars.fill" : "sun.max.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.multicolor)
            }
            .animation(.easeInOut(duration: 0.5), value: status)

            Text(status.isFasting ? "Fasting" : "Eating Window")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(status.isFasting ? Color.green : Color.red)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: status)

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

            let schedule = selectedPreset.schedule
            HStack(spacing: 0) {
                Label {
                    Text("\(schedule.fastingWindowDurationHours)h fast")
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.indigo)
                }
                .font(.subheadline)

                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

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

            VStack(spacing: 8) {
                GeometryReader { geo in
                    let width = geo.size.width
                    let totalHours: CGFloat = 24
                    let hourWidth = width / totalHours

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.indigo.opacity(0.12))
                            .frame(height: 28)

                        let eatStartX = CGFloat(startHour) * hourWidth
                        let eatWidth: CGFloat = endHour > startHour
                            ? CGFloat(endHour - startHour) * hourWidth
                            : (CGFloat(24 - startHour) + CGFloat(endHour)) * hourWidth

                        Capsule()
                            .fill(Color.orange.gradient)
                            .frame(width: eatWidth, height: 28)
                            .offset(x: eatStartX)
                    }
                }
                .frame(height: 28)

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

    // MARK: - Streak (Premium Feature)

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Streak", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.indigo)
                Spacer()
                if !premiumManager.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if premiumManager.isPremium {
                let streak = StreakTracker.shared
                HStack(spacing: 20) {
                    streakStat(value: "\(streak.currentStreak)", label: "Current Streak")
                    streakStat(value: "\(streak.longestStreak)", label: "Longest Streak")
                }

                let history = streak.recentHistory(days: 14)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 14), spacing: 4) {
                    ForEach(history) { day in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(day.didFast ? Color.green : Color.gray.opacity(0.25))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(height: 24)

                Text("Last 14 days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    Text("Track your fasting streaks and build momentum.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Unlock with Premium") {
                        showPaywall = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func streakStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.indigo)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
                          value: "\(schedule.fastingWindowDurationHours)h / \(schedule.eatingWindowDurationHours)h")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Premium CTA

    private var premiumCTA: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.subheadline)
                Text("Go Premium")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .foregroundStyle(.white)
            .background(.indigo.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await PremiumManager.shared.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(.indigo)
    }

    // MARK: - Helpers

    private var timeRemaining: String {
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