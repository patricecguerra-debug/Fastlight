import Foundation

// MARK: - Deprecated Type Aliases

/// Legacy type alias. Use `WindowStatus` instead.
@available(*, deprecated, renamed: "WindowStatus")
public typealias FastingState = WindowStatus

// MARK: - FastingSchedule Extension for Backward Compatibility

public extension FastingSchedule {
    /// Determines the fasting state at the given date.
    /// - Parameters:
    ///   - date: The date to evaluate (default: now).
    ///   - timeZone: The timezone to use (default: current).
    /// - Returns: The current window status.
    @available(*, deprecated, message: "Use state(at:timeZone:) with explicit timeZone parameter")
    func state(at date: Date = Date(), calendar: Calendar = .current) -> WindowStatus {
        state(at: date, timeZone: calendar.timeZone)
    }
}

/// Legacy initializer for `FastingSchedule` without a label.
extension FastingSchedule {
    @available(*, deprecated, message: "Use init(eatingWindowStartHour:eatingWindowEndHour:label:) instead")
    init(eatingWindowStartHour: Int, eatingWindowEndHour: Int) {
        self.init(eatingWindowStartHour: eatingWindowStartHour, eatingWindowEndHour: eatingWindowEndHour, label: "")
    }
}