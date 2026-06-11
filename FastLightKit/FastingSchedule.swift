import Foundation

/// A fasting schedule defines the daily eating window relative to a start hour.
///
/// Supports both normal ranges (e.g., 12:00–20:00 for 16:8) and overnight
/// ranges that wrap past midnight (e.g., 20:00–12:00 for a night-eating schedule).
public struct FastingSchedule: Equatable, Sendable {
    /// The hour (0-23) when the eating window begins.
    public let eatingWindowStartHour: Int

    /// The hour (0-23) when the eating window ends.
    /// If this is less than or equal to `startHour`, the window wraps past midnight.
    public let eatingWindowEndHour: Int

    /// A human-readable label (e.g. "16:8", "18:6").
    public let label: String

    public init(
        eatingWindowStartHour: Int,
        eatingWindowEndHour: Int,
        label: String = ""
    ) {
        self.eatingWindowStartHour = eatingWindowStartHour
        self.eatingWindowEndHour = eatingWindowEndHour
        self.label = label
    }

    // MARK: - State Calculation

    /// Calculates the fasting state at the given date, in the given timezone.
    /// - Parameters:
    ///   - date: The date to evaluate (default: now).
    ///   - timeZone: The user's timezone (default: current).
    /// - Returns: The corresponding `WindowStatus`.
    public func state(at date: Date = Date(), timeZone: TimeZone = .current) -> WindowStatus {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)

        if eatingWindowStartHour <= eatingWindowEndHour {
            // Normal range (e.g., 12:00 - 20:00 for 16:8)
            if hour >= eatingWindowStartHour && hour < eatingWindowEndHour {
                return .eating
            } else {
                return .fasting
            }
        } else {
            // Overnight window wrapping past midnight (e.g., 20:00 - 12:00)
            if hour >= eatingWindowStartHour || hour < eatingWindowEndHour {
                return .eating
            } else {
                return .fasting
            }
        }
    }

    // MARK: - Convenience

    /// The total duration of the eating window in hours.
    public var eatingWindowDurationHours: Int {
        if eatingWindowEndHour > eatingWindowStartHour {
            return eatingWindowEndHour - eatingWindowStartHour
        } else {
            // Wraps past midnight
            return (24 - eatingWindowStartHour) + eatingWindowEndHour
        }
    }

    /// The total duration of the fasting window in hours (24 - eating).
    public var fastingWindowDurationHours: Int {
        24 - eatingWindowDurationHours
    }

    /// Returns `true` if the eating window wraps past midnight.
    public var wrapsPastMidnight: Bool {
        eatingWindowEndHour <= eatingWindowStartHour
    }

    // MARK: - Common IF Presets

    /// Common intermittent fasting schedule presets.
    public enum Preset: CaseIterable, Sendable {
        /// 16 hours fasting, 8 hours eating (most common).
        case sixteenEight
        /// 18 hours fasting, 6 hours eating.
        case eighteenSix
        /// 20 hours fasting, 4 hours eating (OMAD — One Meal A Day).
        case twentyFour
        /// 14 hours fasting, 10 hours eating (beginner-friendly).
        case fourteenTen
        /// 12 hours fasting, 12 hours eating (balanced).
        case twelveTwelve

        public var schedule: FastingSchedule {
            switch self {
            case .sixteenEight:
                return FastingSchedule(
                    eatingWindowStartHour: 12,
                    eatingWindowEndHour: 20,
                    label: "16:8"
                )
            case .eighteenSix:
                return FastingSchedule(
                    eatingWindowStartHour: 14,
                    eatingWindowEndHour: 20,
                    label: "18:6"
                )
            case .twentyFour:
                return FastingSchedule(
                    eatingWindowStartHour: 16,
                    eatingWindowEndHour: 20,
                    label: "20:4"
                )
            case .fourteenTen:
                return FastingSchedule(
                    eatingWindowStartHour: 10,
                    eatingWindowEndHour: 20,
                    label: "14:10"
                )
            case .twelveTwelve:
                return FastingSchedule(
                    eatingWindowStartHour: 8,
                    eatingWindowEndHour: 20,
                    label: "12:12"
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
            }
        }

        /// Detailed description of the schedule.
        public var description: String {
            "\(fastingHours)h fast / \(eatingHours)h eat window"
        }

        private var fastingHours: Int { 24 - schedule.eatingWindowDurationHours }
        private var eatingHours: Int { schedule.eatingWindowDurationHours }
    }
}

// MARK: - FastingSchedule + Preset Convenience

public extension FastingSchedule {
    /// Create a schedule from one of the built-in presets.
    /// - Parameter preset: The preset schedule to use.
    /// - Returns: A `FastingSchedule` configured for the given preset.
    static func fromPreset(_ preset: Preset) -> FastingSchedule {
        preset.schedule
    }
}