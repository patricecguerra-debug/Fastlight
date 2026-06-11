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
    ///   - timeZone: The timezone to use for hour calculation.
    /// - Returns: `.fasting` or `.eating`.
    public func status(at date: Date, timeZone: TimeZone = .current) -> WindowStatus {
        schedule.state(at: date, timeZone: timeZone)
    }

    // MARK: - Time Remaining

    /// Returns the time remaining in the current window (fasting or eating).
    /// - Parameter timeZone: The user's timezone.
    /// - Returns: The duration until the next transition, or nil if it can't be determined.
    public func timeRemainingInCurrentWindow(timeZone: TimeZone = .current) -> TimeInterval? {
        let now = Date()
        let status = currentStatus(timeZone: timeZone)
        guard let nextTransition = nextTransition(after: now, timeZone: timeZone) else {
            return nil
        }
        return nextTransition.timeIntervalSince(now)
    }

    /// Returns the date of the next state transition (when fasting/eating switches).
    /// - Parameters:
    ///   - date: The date to start from.
    ///   - timeZone: The timezone to use.
    /// - Returns: The date of the next transition.
    public func nextTransition(after date: Date = Date(), timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let currentStatus = status(at: date, timeZone: timeZone)
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)

        // Determine the next transition hour
        let transitionHour: Int
        if currentStatus == .fasting {
            // We're fasting — next transition is the start of the eating window
            transitionHour = schedule.eatingWindowStartHour
        } else {
            // We're eating — next transition is the end of the eating window
            transitionHour = schedule.eatingWindowEndHour
        }

        // Build a candidate date for today at the transition hour
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = transitionHour
        components.minute = 0
        components.second = 0

        guard var transitionDate = calendar.date(from: components) else {
            return nil
        }

        // If the transition has already passed today, move to tomorrow
        if transitionDate <= date {
            transitionDate = calendar.date(byAdding: .day, value: 1, to: transitionDate)!
        }

        return transitionDate
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

        if let remaining = timeRemainingInCurrentWindow(timeZone: timeZone) {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let timeString: String
            if hours > 0 {
                timeString = "\(h)h \(minutes)m remaining"
            } else {
                timeString = "\(minutes)m remaining"
            }
            return "\(baseDescription) · \(timeString)"
        }

        return baseDescription
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