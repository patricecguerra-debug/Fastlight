import Foundation

/// The central engine for determining fasting state.
///
/// `FastLightEngine` is the main entry point for evaluating whether a user
/// is currently in their fasting or eating window. It is timezone-aware
/// and supports all common intermittent fasting schedules.
///
/// Usage:
/// ```swift
/// let engine = FastLightEngine(schedule: .fromPreset(.sixteenEight))
/// let status = engine.currentStatus()  // => .fasting or .eating
/// ```
public struct FastLightEngine: Equatable, Sendable {
    /// The user's configured fasting schedule.
    public var schedule: FastingSchedule

    /// Creates an engine with the given schedule.
    /// - Parameter schedule: The fasting schedule to evaluate against.
    public init(schedule: FastingSchedule) {
        self.schedule = schedule
    }

    // MARK: - Status Queries

    /// Returns the current fasting status based on the configured schedule
    /// and the user's current timezone.
    public func currentStatus(timeZone: TimeZone = .current) -> WindowStatus {
        status(at: Date(), timeZone: timeZone)
    }

    /// Returns the fasting status at a specific date and timezone.
    /// - Parameters:
    ///   - date: The date to evaluate.
    ///   - timeZone: The timezone to use for calculation.
    /// - Returns: `.fasting` or `.eating`.
    public func status(at date: Date, timeZone: TimeZone = .current) -> WindowStatus {
        schedule.state(at: date, timeZone: timeZone)
    }

    // MARK: - Remaining Time

    /// Returns the time remaining in the current window (fasting or eating).
    /// - Parameter timeZone: The user's timezone.
    /// - Returns: The duration until the next transition.
    public func timeRemainingInCurrentWindow(timeZone: TimeZone = .current) -> TimeInterval {
        let now = Date()
        let nextTransition = schedule.nextTransitionDate(after: now, timeZone: timeZone)
        return nextTransition.timeIntervalSince(now)
    }

    /// Returns the date of the next state transition (when fasting/eating switches).
    /// - Parameters:
    ///   - date: The date to start from.
    ///   - timeZone: The timezone to use.
    /// - Returns: The date of the next transition.
    public func nextTransition(after date: Date = Date(), timeZone: TimeZone = .current) -> Date {
        schedule.nextTransitionDate(after: date, timeZone: timeZone)
    }

    /// A human-readable string of remaining time until the next state change.
    /// - Parameter timeZone: The user's timezone.
    /// - Returns: A string like "2h 15m until eating" or "45m until fasting".
    public func timeRemainingString(timeZone: TimeZone = .current) -> String {
        schedule.timeRemainingString(at: Date(), timeZone: timeZone)
    }

    /// The precise time when the widget should next refresh (1 minute before each transition).
    /// - Parameters:
    ///   - date: The reference date (default: now).
    ///   - timeZone: The timezone to use.
    /// - Returns: A date shortly before the next state change.
    public func nextRefreshDate(after date: Date = Date(), timeZone: TimeZone = .current) -> Date {
        schedule.nextRefreshDate(after: date, timeZone: timeZone)
    }

    // MARK: - State Description

    /// A human-readable summary of the current state.
    /// - Parameter timeZone: The user's timezone.
    /// - Returns: A localized string describing the current state.
    public func statusDescription(timeZone: TimeZone = .current) -> String {
        let status = currentStatus(timeZone: timeZone)
        switch status {
        case .fasting:
            return "Fasting"
        case .eating:
            return "Eating window"
        }
    }

    /// A detailed description including time remaining.
    /// - Parameter timeZone: The user's timezone.
    /// - Returns: A detailed status string.
    public func detailedStatusDescription(timeZone: TimeZone = .current) -> String {
        let status = currentStatus(timeZone: timeZone)
        let baseDescription = statusDescription(timeZone: timeZone)

        let remaining = timeRemainingInCurrentWindow(timeZone: timeZone)
        let totalMinutes = Int(remaining) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let timeString: String
        if hours > 0 {
            timeString = "\(hours)h \(minutes)m remaining"
        } else {
            timeString = "\(minutes)m remaining"
        }
        return "\(baseDescription) · \(timeString)"
    }
}

// MARK: - Factory Conveniences

public extension FastLightEngine {
    /// Creates an engine pre-configured with the 16:8 schedule (most common).
    static var sixteenEight: FastLightEngine {
        FastLightEngine(schedule: .fromPreset(.sixteenEight))
    }

    /// Creates an engine pre-configured with the 18:6 schedule.
    static var eighteenSix: FastLightEngine {
        FastLightEngine(schedule: .fromPreset(.eighteenSix))
    }

    /// Creates an engine pre-configured with the 20:4 (OMAD) schedule.
    static var twentyFour: FastLightEngine {
        FastLightEngine(schedule: .fromPreset(.twentyFour))
    }
}