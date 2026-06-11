import Foundation

/// Represents whether the user is currently fasting or in their eating window.
public enum WindowStatus: Equatable, Sendable {
    case fasting
    case eating

    public var isFasting: Bool { self == .fasting }
    public var isEating: Bool { self == .eating }
}