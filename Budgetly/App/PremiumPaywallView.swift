import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var storeService

    var body: some View {
        SubscriptionStoreView(productIDs: [
            "com.budgetly.premium.monthly",
            "com.budgetly.premium.yearly"
        ]) {
            VStack(spacing: 16) {
                Text("Поддержите разработку с премиум-подпиской").font(.title.bold())
                Text("3 дня бесплатно, затем авто-возобновление…").multilineTextAlignment(.center)
                Text("Отмена в любое время…").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .background(.blue.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePolicyDestination(url: URL(string:"https://your-site/terms")!, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: URL(string:"https://your-site/privacy")!, for: .privacyPolicy)
        .onInAppPurchaseCompletion { _, _ in
            dismiss()
            Task { await storeService.refreshPremiumStatus() }
        }
    }
}


// StoreServiceKey.swift
//import SwiftUI
//
//private struct StoreServiceKey: EnvironmentKey {
//    // НИЧЕГО не создаём здесь
//    static var defaultValue: StoreService {
//        fatalError("StoreService is not injected. Provide it via .environment(\\.storeService, …)")
//    }
//}
//
//extension EnvironmentValues {
//    var storeService: StoreService {
//        get { self[StoreServiceKey.self] }
//        set { self[StoreServiceKey.self] = newValue }
//    }
//}

