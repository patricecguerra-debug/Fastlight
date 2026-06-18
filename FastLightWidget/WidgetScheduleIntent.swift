import AppIntents
import FastLightKit

/// The fasting schedule options available in the widget configuration.
enum WidgetSchedulePreset: String, AppEnum {
    case sixteenEight
    case eighteenSix
    case twentyFour
    case fourteenTen
    case twelveTwelve

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Fasting Schedule"
    }

    static var caseDisplayRepresentations: [WidgetSchedulePreset: DisplayRepresentation] {
        [
            .sixteenEight: "16:8 (Standard)",
            .eighteenSix: "18:6 (Lean Gains)",
            .twentyFour: "20:4 (OMAD)",
            .fourteenTen: "14:10 (Beginner)",
            .twelveTwelve: "12:12 (Balanced)",
        ]
    }

    /// Convert to the framework's `FastingSchedule.Preset`.
    var fastLightPreset: FastingSchedule.Preset {
        switch self {
        case .sixteenEight: return .sixteenEight
        case .eighteenSix: return .eighteenSix
        case .twentyFour: return .twentyFour
        case .fourteenTen: return .fourteenTen
        case .twelveTwelve: return .twelveTwelve
        }
    }
}

/// Intent that lets users pick their fasting schedule from the widget's edit menu.
struct ScheduleSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Schedule"
    static var description: LocalizedStringResource = "Choose your preferred fasting schedule."

    @Parameter(title: "Fasting Schedule", default: .sixteenEight)
    var preset: WidgetSchedulePreset
}