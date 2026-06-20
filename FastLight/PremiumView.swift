import SwiftUI
import FastLightKit

/// Displays premium features and handles purchase/restore flow.
struct PremiumView: View {
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
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

                // Feature list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(PremiumFeature.allCases, id: \.self) { feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(.indigo)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "lock.open.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Purchase button
                VStack(spacing: 12) {
                    Button(action: purchasePremium) {
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
                }

                // Restore purchases
                Button(action: restorePurchases) {
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
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { showAlert = false }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Actions

    private func purchasePremium() {
        isPurchasing = true
        Task {
            do {
                let success = try await PremiumManager.shared.purchase()
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        alertTitle = "Welcome to Premium!"
                        alertMessage = "All premium features are now unlocked."
                    }
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertTitle = "Purchase Failed"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            let restored = await PremiumManager.shared.restorePurchases()
            await MainActor.run {
                isRestoring = false
                if restored {
                    alertTitle = "Purchases Restored"
                    alertMessage = "Your premium access has been restored."
                } else {
                    alertTitle = "No Purchases Found"
                    alertMessage = "We couldn't find any previous purchases to restore."
                }
                showAlert = true
            }
        }
    }
}

#Preview {
    PremiumView()
}