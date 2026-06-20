import Foundation
import StoreKit
import SwiftUI

/// Manages in-app purchases for FastLight Premium using StoreKit 2.
/// Uses `@Published` properties for SwiftUI reactivity.
@MainActor
public final class PremiumManager: ObservableObject {
    // MARK: - Product IDs

    public static let premiumProductID = "com.fastlight.premium"

    // MARK: - Singleton

    public static let shared = PremiumManager()

    // MARK: - Published State

    /// Whether the user is currently premium. Published for SwiftUI.
    @Published public var isPremium: Bool = false

    private init() {
        // Check cached state immediately
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        // Verify with StoreKit
        Task {
            await verifyPurchase()
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase for the premium product.
    /// - Returns: `true` if the purchase succeeded.
    @discardableResult
    public func purchase() async -> Bool {
        guard let product = try? await Product.products(for: [Self.premiumProductID]).first else {
            return false
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            return false
        }

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                isPremium = true
                UserDefaults.standard.set(true, forKey: "isPremium")
                return true
            case .unverified:
                return false
            }

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    /// Restores previously made purchases.
    /// - Returns: `true` if any premium transactions were restored.
    @discardableResult
    public func restorePurchases() async -> Bool {
        var restored = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID {
                restored = true
            }
        }

        if restored {
            isPremium = true
            UserDefaults.standard.set(true, forKey: "isPremium")
        }

        return restored
    }

    // MARK: - Verification

    private func verifyPurchase() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                isPremium = true
                UserDefaults.standard.set(true, forKey: "isPremium")
                return
            }
        }
        // No valid transaction found
        isPremium = false
        UserDefaults.standard.set(false, forKey: "isPremium")
    }
}

// MARK: - Premium Features

/// Features that are locked behind the Premium purchase.
public enum PremiumFeature: String, CaseIterable, Sendable {
    case streakTracking = "Advanced Streak Tracking"
    case widgetThemes = "Widget Color Themes"
    case customSchedule = "Custom Schedule Builder"

    public var description: String {
        switch self {
        case .streakTracking:
            return "Track your fasting streaks and history"
        case .widgetThemes:
            return "Custom widget colors, themes, and text"
        case .customSchedule:
            return "Build custom fasting schedules"
        }
    }

    public var icon: String {
        switch self {
        case .streakTracking: return "flame.fill"
        case .widgetThemes: return "paintpalette.fill"
        case .customSchedule: return "slider.horizontal.3"
        }
    }
}