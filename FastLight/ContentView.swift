import SwiftUI
import FastLightKit

struct ContentView: View {
    @State private var schedule = FastingSchedule(
        eatingWindowStartHour: 12,
        eatingWindowEndHour: 20
    )

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(.indigo)

            Text("FastLight")
                .font(.largeTitle)
                .fontWeight(.bold)

            statusCard
                .padding(.horizontal)

            scheduleSection
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 60)
    }

    private var statusCard: some View {
        let state = schedule.state()
        return HStack {
            Circle()
                .fill(state.isFasting ? Color.green : Color.red)
                .frame(width: 16, height: 16)

            Text(state.isFasting ? "You are fasting" : "Eating window")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)

            HStack {
                Text("Eating window")
                Spacer()
                Text("\(schedule.eatingWindowStartHour):00 – \(schedule.eatingWindowEndHour):00")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContentView()
}
