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
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Премиум-подписка")
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text("Поддержите разработку и получите доступ ко всем функциям без ограничений.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        FeatureItem(icon: "infinity", title: "Неограниченное количество операций", description: "Добавляйте сколько угодно транзакций в день (бесплатно — до 2 в день).")
                        FeatureItem(icon: "plus.circle", title: "Свои категории", description: "Создавайте и редактируйте собственные категории доходов и расходов.")
                        FeatureItem(icon: "cloud.fill", title: "Синхронизация через iCloud", description: "Данные доступны на всех ваших устройствах (если включено).")
                        FeatureItem(icon: "lock.open.fill", title: "Все будущие обновления", description: "Доступ к новым функциям без дополнительных платежей.")
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStorePolicyDestination(
                url: URL(string: "https://project14182049.tilda.ws")!, for: .termsOfService)
            .subscriptionStorePolicyDestination(
                url: URL(string: "https://github.com/ViktorNikolaevi4/Budgetly/blob/main/PRIVACY_POLICY.md")!, for: .privacyPolicy)
            .onInAppPurchaseCompletion { _, _ in
                Task { await storeService.refreshPremiumStatus() }
            }
            .padding(.horizontal)
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
