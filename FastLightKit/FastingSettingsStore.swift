import Foundation

/// Simple AppGroup-backed store for the user's selected fasting preset.
/// Both the app and the widget read from the same store via the shared AppGroup container.
public final class FastingSettingsStore: @unchecked Sendable {
    private let defaults: UserDefaults

    public static let shared = FastingSettingsStore()

    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.fastlight")!
    }

    // For testing / preview injection
    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The user's selected preset. Defaults to `.sixteenEight` if nothing is saved.
    public var selectedPreset: FastingSchedule.Preset {
        get {
            guard let rawValue = defaults.string(forKey: "selectedPreset") else {
                return .sixteenEight
            }
            return preset(from: rawValue)
        }
        set {
            defaults.set(rawValue(for: newValue), forKey: "selectedPreset")
        }
    }

    // MARK: - Encoding

    private func preset(from rawValue: String) -> FastingSchedule.Preset {
        switch rawValue {
        case "sixteenEight": return .sixteenEight
        case "eighteenSix": return .eighteenSix
        case "twentyFour": return .twentyFour
        case "fourteenTen": return .fourteenTen
        case "twelveTwelve": return .twelveTwelve
        case "custom": return .custom(startHour: 12, endHour: 20)
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