import Foundation

/// Represents the current fasting state of the user.
enum FastingState: Equatable {
    case fasting
    case eating

    var isFasting: Bool { self == .fasting }
}

/// Configuration for a user's fasting schedule.
struct FastingSchedule: Equatable {
    /// The hour (0-23) when the eating window starts.
    let eatingWindowStartHour: Int
    /// The hour (0-23) when the eating window ends.
    let eatingWindowEndHour: Int

    /// Determines the fasting state at the given date.
    func state(at date: Date = Date(), calendar: Calendar = .current) -> FastingState {
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
