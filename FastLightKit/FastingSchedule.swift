import Foundation

/// A fasting schedule defines the daily eating window with minute-level precision.
///
/// Supports both normal ranges (e.g., 12:00–20:00 for 16:8) and overnight
/// ranges that wrap past midnight (e.g., 20:00–12:00 for a night-eating schedule).
public struct FastingSchedule: Equatable, Sendable {
    // MARK: - Properties

    /// The hour (0-23) when the eating window begins.
    public let eatingWindowStartHour: Int
    /// The minute (0-59) when the eating window begins.
    public let eatingWindowStartMinute: Int

    /// The hour (0-23) when the eating window ends.
    /// If less than `startHour`, the window wraps past midnight.
    public let eatingWindowEndHour: Int
    /// The minute (0-59) when the eating window ends.
    public let eatingWindowEndMinute: Int

    /// A human-readable label (e.g. "16:8", "18:6").
    public let label: String

    public init(
        eatingWindowStartHour: Int,
        eatingWindowStartMinute: Int = 0,
        eatingWindowEndHour: Int,
        eatingWindowEndMinute: Int = 0,
        label: String = ""
    ) {
        self.eatingWindowStartHour = eatingWindowStartHour
        self.eatingWindowStartMinute = eatingWindowStartMinute
        self.eatingWindowEndHour = eatingWindowEndHour
        self.eatingWindowEndMinute = eatingWindowEndMinute
        self.label = label
    }

    // MARK: - State Calculation (Minute-Level Precision)

    /// Calculates the fasting state at the given date, in the given timezone.
    /// - Parameters:
    ///   - date: The date to evaluate (default: now).
    ///   - timeZone: The user's timezone (default: current).
    /// - Returns: The corresponding `WindowStatus`.
    public func state(at date: Date = Date(), timeZone: TimeZone = .current) -> WindowStatus {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute

        let startTotalMinutes = eatingWindowStartHour * 60 + eatingWindowStartMinute
        let endTotalMinutes = eatingWindowEndHour * 60 + eatingWindowEndMinute

        if startTotalMinutes <= endTotalMinutes {
            // Normal range (e.g., 12:00 - 20:00 for 16:8)
            if totalMinutes >= startTotalMinutes && totalMinutes < endTotalMinutes {
                return .eating
            } else {
                return .fasting
            }
        } else {
            // Overnight window wrapping past midnight (e.g., 20:00 - 12:00)
            if totalMinutes >= startTotalMinutes || totalMinutes < endTotalMinutes {
                return .eating
            } else {
                return .fasting
            }
        }
    }

    // MARK: - Convenience

    /// Start time as a `(hour, minute)` tuple.
    public var startTime: (hour: Int, minute: Int) {
        (eatingWindowStartHour, eatingWindowStartMinute)
    }

    /// End time as a `(hour, minute)` tuple.
    public var endTime: (hour: Int, minute: Int) {
        (eatingWindowEndHour, eatingWindowEndMinute)
    }

    /// The total duration of the eating window in minutes.
    public var eatingWindowDurationMinutes: Int {
        let startTotal = eatingWindowStartHour * 60 + eatingWindowStartMinute
        let endTotal = eatingWindowEndHour * 60 + eatingWindowEndMinute
        if endTotal > startTotal {
            return endTotal - startTotal
        } else {
            // Wraps past midnight
            return (24 * 60 - startTotal) + endTotal
        }
    }

    /// The total duration of the fasting window in minutes.
    public var fastingWindowDurationMinutes: Int {
        (24 * 60) - eatingWindowDurationMinutes
    }

    /// The total duration of the eating window in hours (approximate).
    public var eatingWindowDurationHours: Int {
        eatingWindowDurationMinutes / 60
    }

    /// The total duration of the fasting window in hours (approximate).
    public var fastingWindowDurationHours: Int {
        fastingWindowDurationMinutes / 60
    }

    /// Returns `true` if the eating window wraps past midnight.
    public var wrapsPastMidnight: Bool {
        let startTotal = eatingWindowStartHour * 60 + eatingWindowStartMinute
        let endTotal = eatingWindowEndHour * 60 + eatingWindowEndMinute
        return endTotal <= startTotal
    }

    /// A human-readable time range string (e.g. "12:00 – 20:00").
    public var timeRangeString: String {
        let start = String(format: "%02d:%02d", eatingWindowStartHour, eatingWindowStartMinute)
        let end = String(format: "%02d:%02d", eatingWindowEndHour, eatingWindowEndMinute)
        return "\(start) – \(end)"
    }

    // MARK: - Schedule Presets

    /// Common intermittent fasting schedule presets.
    public enum Preset: Equatable, Hashable, Sendable, CaseIterable {
        /// All built-in presets for UI display (excludes `.custom`).
        public static var allCases: [Preset] {
            [.sixteenEight, .eighteenSix, .twentyFour, .fourteenTen, .twelveTwelve]
        }
        /// 16 hours fasting, 8 hours eating (most common: 12pm–8pm).
        case sixteenEight
        /// 18 hours fasting, 6 hours eating (12pm–6pm).
        case eighteenSix
        /// 20 hours fasting, 4 hours eating / OMAD (4pm–8pm).
        case twentyFour
        /// 14 hours fasting, 10 hours eating (10am–8pm).
        case fourteenTen
        /// 12 hours fasting, 12 hours eating (8am–8pm).
        case twelveTwelve
        /// Custom schedule with a specific eating window.
        case custom(startHour: Int, endHour: Int)

        public var schedule: FastingSchedule {
            switch self {
            case .sixteenEight:
                return FastingSchedule(
                    eatingWindowStartHour: 12, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: 20, eatingWindowEndMinute: 0,
                    label: "16:8"
                )
            case .eighteenSix:
                return FastingSchedule(
                    eatingWindowStartHour: 12, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: 18, eatingWindowEndMinute: 0,
                    label: "18:6"
                )
            case .twentyFour:
                return FastingSchedule(
                    eatingWindowStartHour: 16, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: 20, eatingWindowEndMinute: 0,
                    label: "20:4"
                )
            case .fourteenTen:
                return FastingSchedule(
                    eatingWindowStartHour: 10, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: 20, eatingWindowEndMinute: 0,
                    label: "14:10"
                )
            case .twelveTwelve:
                return FastingSchedule(
                    eatingWindowStartHour: 8, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: 20, eatingWindowEndMinute: 0,
                    label: "12:12"
                )
            case .custom(let startHour, let endHour):
                let fastingHours = 24 - (endHour - startHour)
                return FastingSchedule(
                    eatingWindowStartHour: startHour, eatingWindowStartMinute: 0,
                    eatingWindowEndHour: endHour, eatingWindowEndMinute: 0,
                    label: "\(fastingHours):\(endHour - startHour)"
                )
            }
        }

        /// Display name for UI.
        public var displayName: String {
            switch self {
            case .sixteenEight: return "16:8 (Standard)"
            case .eighteenSix: return "18:6 (Lean Gains)"
            case .twentyFour: return "20:4 (OMAD)"
            case .fourteenTen: return "14:10 (Beginner)"
            case .twelveTwelve: return "12:12 (Balanced)"
            case .custom(let start, let end): return "Custom (\(start):00–\(end):00)"
            }
        }

        /// Detailed description of the schedule.
        public var description: String {
            switch self {
            case .custom:
                let sched = schedule
                return "\(sched.fastingWindowDurationHours)h fast / \(sched.eatingWindowDurationHours)h eat"
            default:
                let sched = schedule
                return "\(sched.fastingWindowDurationHours)h fast / \(sched.eatingWindowDurationHours)h eat"
            }
        }
    }
}

// MARK: - Preset Convenience

public extension FastingSchedule {
    /// Create a schedule from one of the built-in presets.
    static func fromPreset(_ preset: Preset) -> FastingSchedule {
        preset.schedule
    }
}

// MARK: - Time Remaining

public extension FastingSchedule {
    /// Returns a human-readable string of how much time is left until the next state change.
    /// - Parameters:
    ///   - date: The reference date (default: now).
    ///   - timeZone: The timezone to use.
    /// - Returns: A string like "2h 15m remaining" or "45m remaining".
    func timeRemainingString(at date: Date = Date(), timeZone: TimeZone = .current) -> String {
        let currentState = state(at: date, timeZone: timeZone)
        let nextDate = nextTransitionDate(after: date, timeZone: timeZone)
        let interval = nextDate.timeIntervalSince(date)

        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if currentState == .fasting {
            if hours > 0 {
                return "\(hours)h \(minutes)m until eating"
            } else {
                return "\(minutes)m until eating"
            }
        } else {
            if hours > 0 {
                return "\(hours)h \(minutes)m until fasting"
            } else {
                return "\(minutes)m until fasting"
            }
        }
    }

    /// Calculates the exact date when the next state transition will occur.
    /// - Parameters:
    ///   - date: The reference date (default: now).
    ///   - timeZone: The timezone to use.
    /// - Returns: The date of the next transition.
    func nextTransitionDate(after date: Date = Date(), timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let currentState = state(at: date, timeZone: timeZone)

        // Determine the transition time (hour:minute)
        let transitionHour: Int
        let transitionMinute: Int
        if currentState == .fasting {
            transitionHour = eatingWindowStartHour
            transitionMinute = eatingWindowStartMinute
        } else {
            transitionHour = eatingWindowEndHour
            transitionMinute = eatingWindowEndMinute
        }

        // Build a candidate date for today at the transition time
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = transitionHour
        components.minute = transitionMinute
        components.second = 0

        guard var transitionDate = calendar.date(from: components) else {
            // Fallback: 1 hour from now
            return date.addingTimeInterval(3600)
        }

        // If the transition has already passed today, move to tomorrow
        if transitionDate <= date {
            transitionDate = calendar.date(byAdding: .day, value: 1, to: transitionDate)!
        }

        return transitionDate
    }

    /// Calculates the precise next refresh date for widgets — right before the next transition.
    /// - Parameter date: The reference date (default: now).
    /// - Returns: A date shortly before the next state change (1 minute prior).
    func nextRefreshDate(after date: Date = Date(), timeZone: TimeZone = .current) -> Date {
        let transition = nextTransitionDate(after: date, timeZone: timeZone)
        // Refresh 1 minute before transition so the widget flips on time
        return transition.addingTimeInterval(-60)
    }
}