import Foundation
import StoreKit

/// Manages in-app purchases for FastLight Premium using StoreKit 2.
///
/// Usage:
/// ```swift
/// let manager = PremiumManager.shared
/// let isPremium = await manager.isPremium
/// try await manager.purchase()
/// await manager.restorePurchases()
/// ```
@available(iOS 17.0, *)
public final class PremiumManager: @unchecked Sendable {
    // MARK: - Product IDs

    public enum ProductID: String {
        case premium = "com.fastlight.premium.lifetime"
    }

    // MARK: - Singleton

    public static let shared = PremiumManager()

    private init() {}

    // MARK: - Purchased State

    /// Whether the user is currently premium.
    /// Checks the transaction for the premium product.
    public var isPremium: Bool {
        get async {
            await verifyPurchase()
        }
    }

    /// Synchronous cached check (for non-async contexts like widget timeline).
    /// Relies on UserDefaults fallback that's updated after each purchase.
    public var isPremiumCached: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }

    // MARK: - Purchase

    /// Initiates a purchase for the premium lifetime product.
    /// - Returns: `true` if the purchase succeeded.
    @discardableResult
    public func purchase() async throws -> Bool {
        guard let product = try await Product.products(for: [ProductID.premium.rawValue]).first else {
            throw PremiumError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            // Cache the purchase state
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "isPremium")
            }
            return true

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
        // Force a refresh by checking all transactions
        var restored = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProductID.premium.rawValue {
                    restored = true
                    await MainActor.run {
                        UserDefaults.standard.set(true, forKey: "isPremium")
                    }
                }
            }
        }
        return restored
    }

    // MARK: - Verification

    private func verifyPurchase() async -> Bool {
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProductID.premium.rawValue {
                    // Check if the transaction is still valid (not expired/revoked)
                    if transaction.revocationDate == nil {
                        return true
                    }
                }
            }
        }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PremiumError.verificationFailed
        }
    }
}

// MARK: - Errors

public enum PremiumError: LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed

    public var errorDescription: String? {
        switch self {
        case .productNotFound: return "Premium product not found in App Store."
        case .verificationFailed: return "Transaction verification failed."
        case .purchaseFailed: return "Purchase failed. Please try again."
        }
    }
}

// MARK: - Premium Features

/// Features that are locked behind the Premium purchase.
public enum PremiumFeature: String, CaseIterable, Sendable {
    case streakTracking = "Streak Tracking"
    case customWidgetThemes = "Widget Themes & Colors"
    case advancedScheduling = "Advanced Scheduling"
    case allPresets = "All Schedule Presets"

    public var description: String {
        switch self {
        case .streakTracking:
            return "Track your fasting streaks and history"
        case .customWidgetThemes:
            return "Custom widget colors, themes, and text"
        case .advancedScheduling:
            return "Custom schedules and minute-level precision"
        case .allPresets:
            return "All 5 fasting schedule presets"
        }
    }

    public var icon: String {
        switch self {
        case .streakTracking: return "flame.fill"
        case .customWidgetThemes: return "paintpalette.fill"
        case .advancedScheduling: return "slider.horizontal.3"
        case .allPresets: return "list.bullet"
        }
    }
}