import SwiftUI
import FastLightKit

/// Paywall screen showing free vs premium feature comparison.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var purchaseSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: isPurchasing)

                    Text("FastLight Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Unlock the full fasting experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Free vs Premium comparison
                VStack(spacing: 0) {
                    // Free tier
                    tierRow(
                        icon: "moon.stars.fill",
                        title: "Free",
                        items: [
                            "Basic widget with green/red status",
                            "5 fasting schedule presets",
                            "Standard colors"
                        ],
                        isPremium: false
                    )

                    Divider()
                        .padding(.horizontal)

                    // Premium tier
                    tierRow(
                        icon: "crown.fill",
                        title: "Premium",
                        items: [
                            "Advanced streak tracking",
                            "Widget color themes",
                            "Custom schedule builder"
                        ],
                        isPremium: true
                    )
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Buy button
                VStack(spacing: 12) {
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "crown.fill")
                                Text("Upgrade to Premium")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.indigo.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isPurchasing)
                    .buttonStyle(.plain)

                    Text("One-time purchase • Lifetime access")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: restore) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                            } else {
                                Text("Restore Purchases")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.indigo)
                    }
                    .disabled(isRestoring)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if purchaseSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Tier Row

    private func tierRow(icon: String, title: String, items: [String], isPremium: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(isPremium ? .yellow : .indigo)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: isPremium ? "checkmark.circle.fill" : "circle.fill")
                            .font(.caption)
                            .foregroundStyle(isPremium ? .green : .secondary.opacity(0.5))
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(isPremium ? .primary : .secondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func purchase() {
        isPurchasing = true
        Task {
            let success = await PremiumManager.shared.purchase()
            await MainActor.run {
                isPurchasing = false
                if success {
                    alertTitle = "Welcome to Premium!"
                    alertMessage = "All premium features are now unlocked."
                    purchaseSuccess = true
                } else {
                    alertTitle = "Purchase Cancelled"
                    alertMessage = "The purchase was cancelled or could not be completed."
                    purchaseSuccess = false
                }
                showAlert = true
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            let restored = await PremiumManager.shared.restorePurchases()
            await MainActor.run {
                isRestoring = false
                if restored {
                    alertTitle = "Purchases Restored"
                    alertMessage = "Your premium access has been restored."
                    purchaseSuccess = true
                } else {
                    alertTitle = "No Purchases Found"
                    alertMessage = "We couldn't find any previous purchases to restore."
                    purchaseSuccess = false
                }
                showAlert = true
            }
        }
    }
}

#Preview {
    PaywallView()
}