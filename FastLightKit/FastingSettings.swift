import Foundation

/// Persists the user's fasting schedule selection to UserDefaults in an AppGroup,
/// so both the main app and the widget can read the same settings.
///
/// AppGroup identifier: `group.com.fastlight`
public final class FastingSettings: @unchecked Sendable {
    // MARK: - UserDefaults Keys

    private enum Key: String {
        case selectedPresetRawValue
        case customStartHour
        case customEndHour
    }

    // MARK: - Singleton

    /// The shared settings instance, backed by the AppGroup UserDefaults.
    public static let shared = FastingSettings()

    // MARK: - Storage

    private let defaults: UserDefaults

    /// Creates a `FastingSettings` instance backed by the given `UserDefaults`.
    /// - Parameter defaults: Defaults to use. Defaults to `UserDefaults(suiteName: "group.com.fastlight")`.
    public init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else {
            self.defaults = UserDefaults(suiteName: "group.com.fastlight") ?? .standard
        }
    }

    // MARK: - Selected Preset

    /// The user's selected preset, or nil if they haven't chosen one yet.
    public var selectedPreset: FastingSchedule.Preset? {
        get {
            guard let raw = defaults.string(forKey: Key.selectedPresetRawValue.rawValue) else {
                return nil
            }
            return preset(from: raw)
        }
        set {
            if let newValue {
                defaults.set(rawValue(for: newValue), forKey: Key.selectedPresetRawValue.rawValue)
            } else {
                defaults.removeObject(forKey: Key.selectedPresetRawValue.rawValue)
            }
        }
    }

    /// The user's custom start hour (only meaningful when `selectedPreset` is `.custom`).
    public var customStartHour: Int {
        get { defaults.integer(forKey: Key.customStartHour.rawValue) }
        set { defaults.set(newValue, forKey: Key.customStartHour.rawValue) }
    }

    /// The user's custom end hour (only meaningful when `selectedPreset` is `.custom`).
    public var customEndHour: Int {
        get { defaults.integer(forKey: Key.customEndHour.rawValue) }
        set { defaults.set(newValue, forKey: Key.customEndHour.rawValue) }
    }

    // MARK: - Computed Schedule

    /// The currently active `FastingSchedule`. If a preset is selected, returns that.
    /// If none is selected, defaults to 16:8.
    public var currentSchedule: FastingSchedule {
        guard let preset = selectedPreset else {
            return FastingSchedule.fromPreset(.sixteenEight)
        }

        if case .custom = preset {
            // Build custom schedule from stored values
            let start = customStartHour
            let end = customEndHour
            // Validate: if values are unset (both 0), default to 12-20
            if start == 0 && end == 0 {
                return FastingSchedule.fromPreset(.sixteenEight)
            }
            return FastingSchedule.fromPreset(.custom(startHour: start, endHour: end))
        }

        return FastingSchedule.fromPreset(preset)
    }

    // MARK: - Convenience

    /// Saves a preset selection to UserDefaults.
    /// - Parameter preset: The preset to save.
    public func selectPreset(_ preset: FastingSchedule.Preset) {
        selectedPreset = preset
        if case .custom(let start, let end) = preset {
            customStartHour = start
            customEndHour = end
        }
    }

    /// Saves a custom schedule (sets preset to `.custom`).
    public func selectCustom(startHour: Int, endHour: Int) {
        selectedPreset = .custom(startHour: startHour, endHour: endHour)
        customStartHour = startHour
        customEndHour = endHour
    }

    /// Resets settings to default (no preset selected, falls back to 16:8).
    public func resetToDefaults() {
        selectedPreset = nil
        customStartHour = 0
        customEndHour = 0
    }

    // MARK: - Private Helpers

    private func preset(from rawValue: String) -> FastingSchedule.Preset {
        switch rawValue {
        case "sixteenEight": return .sixteenEight
        case "eighteenSix": return .eighteenSix
        case "twentyFour": return .twentyFour
        case "fourteenTen": return .fourteenTen
        case "twelveTwelve": return .twelveTwelve
        case "custom": return .custom(startHour: customStartHour, endHour: customEndHour)
        default: return .sixteenEight
        }
    }

    private func rawValue(for preset: FastingSchedule.Preset) -> String {
        switch preset {
        case .sixteenEight: return "sixteenEight"
        case .eighteenSix: return "eighteenSix"
        case .twentyFour: return "twentyFour"
        case .fourteenTen: return "fourteenTen"
        case .twelveTwelve: return "twelveTwelve"
        case .custom: return "custom"
        }
    }
}