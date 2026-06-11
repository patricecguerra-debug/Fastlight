import Foundation

/// Represents the current fasting state of the user.
public enum FastingState: Equatable, Sendable {
    case fasting
    case eating

    public var isFasting: Bool { self == .fasting }
}

/// Configuration for a user's fasting schedule.
public struct FastingSchedule: Equatable, Sendable {
    /// The hour (0-23) when the eating window starts.
    public let eatingWindowStartHour: Int
    /// The hour (0-23) when the eating window ends.
    public let eatingWindowEndHour: Int

    public init(eatingWindowStartHour: Int, eatingWindowEndHour: Int) {
        self.eatingWindowStartHour = eatingWindowStartHour
        self.eatingWindowEndHour = eatingWindowEndHour
    }

    /// Determines the fasting state at the given date.
    public func state(at date: Date = Date(), calendar: Calendar = .current) -> FastingState {
        let hour = calendar.component(.hour, from: date)
        if eatingWindowStartHour <= eatingWindowEndHour {
            // Normal range (e.g., 12:00 - 20:00)
            if hour >= eatingWindowStartHour && hour < eatingWindowEndHour {
                return .eating
            } else {
                return .fasting
            }
        } else {
            // Wraps past midnight (e.g., 20:00 - 12:00)
            if hour >= eatingWindowStartHour || hour < eatingWindowEndHour {
                return .eating
            } else {
                return .fasting
            }
        }
    }
}