import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(StoreService.self) private var storeService

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: [
                "com.budgetly.premium.monthly",
                "com.budgetly.premium.yearly"
            ]) {
                // Лёгкая шапка без обещаний по триалу
                VStack(spacing: 12) {
                    Text("Поддержите разработку с премиум-подпиской")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("Доступ ко всем функциям без ограничений.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStorePolicyDestination(
                url: URL(string:"https://your-site/terms")!, for: .termsOfService)
            .subscriptionStorePolicyDestination(
                url: URL(string:"https://your-site/privacy")!, for: .privacyPolicy)
            .onInAppPurchaseCompletion { _, _ in
                Task { await storeService.refreshPremiumStatus() } // ← без dismiss
            }
            .padding(.horizontal)
        }
    }
}

