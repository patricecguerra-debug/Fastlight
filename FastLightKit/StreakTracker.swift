import Foundation

/// Tracks the user's fasting streak — consecutive days where the eating
/// window schedule was followed (i.e., the user was in fasting state
/// during the expected fasting hours).
///
/// Streaks are persisted to UserDefaults in the AppGroup so both the
/// app and widget can read them.
public final class StreakTracker: @unchecked Sendable {
    // MARK: - UserDefaults Keys

    private enum Key: String {
        case currentStreak
        case longestStreak
        case lastFastingDate
        case streakHistory
    }

    // MARK: - Singleton

    public static let shared = StreakTracker()

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.fastlight") ?? .standard
    }

    // MARK: - Streak State

    /// Current consecutive fasting day streak.
    public var currentStreak: Int {
        get { defaults.integer(forKey: Key.currentStreak.rawValue) }
        set { defaults.set(newValue, forKey: Key.currentStreak.rawValue) }
    }

    /// The longest streak the user has ever achieved.
    public var longestStreak: Int {
        get { defaults.integer(forKey: Key.longestStreak.rawValue) }
        set { defaults.set(newValue, forKey: Key.longestStreak.rawValue) }
    }

    /// The last date when the user was verified as fasting (stored as timeIntervalSince1970).
    private var lastFastingDate: Date? {
        get {
            let interval = defaults.double(forKey: Key.lastFastingDate.rawValue)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            if let date = newValue {
                defaults.set(date.timeIntervalSince1970, forKey: Key.lastFastingDate.rawValue)
            } else {
                defaults.removeObject(forKey: Key.lastFastingDate.rawValue)
            }
        }
    }

    // MARK: - Streak History

    /// Returns a list of recent days with their fasting status.
    /// - Parameter days: The number of days to look back (default: 14).
    /// - Returns: An array of day records.
    public func recentHistory(days: Int = 14) -> [DayRecord] {
        let calendar = Calendar.current
        let today = Date()
        var records: [DayRecord] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            let dayStart = calendar.startOfDay(for: date)
            let didFast = wasFasting(on: dayStart)
            records.append(DayRecord(date: dayStart, didFast: didFast))
        }

        return records.reversed()
    }

    // MARK: - Logging a Fast Day

    /// Record that the user successfully fasted today. Call this when
    /// the user is verified to be in their fasting window.
    public func logFastDay(date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastFastingDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSince == 1 {
                // Consecutive day — increment streak
                currentStreak += 1
            } else if daysSince == 0 {
                // Same day — no change
                return
            } else {
                // Streak broken — reset
                currentStreak = 1
            }
        } else {
            // First ever fast day
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastFastingDate = today
        saveStreakHistoryEntry(date: today)
    }

    /// Call this when the user breaks their fast (enters eating window).
    public func logFastBroken() {
        // Streak is maintained — the fast was completed successfully
        // Only the next day's check matters
    }

    /// Resets all streak data.
    public func reset() {
        currentStreak = 0
        longestStreak = 0
        lastFastingDate = nil
        defaults.removeObject(forKey: Key.streakHistory.rawValue)
    }

    // MARK: - History Persistence

    private func saveStreakHistoryEntry(date: Date) {
        var history = loadHistory()
        let dayStart = Calendar.current.startOfDay(for: date)
        history[dayStart.timeIntervalSince1970] = true
        saveHistory(history)
    }

    private func wasFasting(on date: Date) -> Bool {
        let history = loadHistory()
        return history[date.timeIntervalSince1970] == true
    }

    private func loadHistory() -> [Double: Bool] {
        guard let data = defaults.data(forKey: Key.streakHistory.rawValue),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        var result: [Double: Bool] = [:]
        for (key, value) in dict {
            if let interval = Double(key) {
                result[interval] = value
            }
        }
        return result
    }

    private func saveHistory(_ history: [Double: Bool]) {
        let dict = Dictionary(uniqueKeysWithValues: history.map { (String($0.key), $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: Key.streakHistory.rawValue)
        }
    }
}

// MARK: - Day Record

public struct DayRecord: Identifiable, Sendable {
    public let date: Date
    public let didFast: Bool

    public var id: Double { date.timeIntervalSince1970 }

    public init(date: Date, didFast: Bool) {
        self.date = date
        self.didFast = didFast
    }
}