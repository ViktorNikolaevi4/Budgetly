import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(StoreService.self) private var storeService

    private let groupID = "21756955"

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: groupID) {
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
        .task {                       // выполнится при показе paywall на устройстве
            await storeService.debugLogProductsAndStatus()
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
import StoreKit


extension StoreService {
    /// Универсальный отладочный лог StoreKit: витрина + продукты (SK2 и SK1)
    func debugLogProductsAndStatus() async {
        // 1) Витрина (SK1 — работает на всех)
        if let sf = SKPaymentQueue.default().storefront {
            print("Storefront(SK1):", sf.identifier, sf.countryCode) // например "USA US"
        } else {
            print("Storefront(SK1): nil")
        }

        let ids = ["com.budgetly.premium.monthly", "com.budgetly.premium.yearly"]

        // 2) Попытка через StoreKit 2
        do {
            let sk2 = try await Product.products(for: ids)
            print("SK2 Loaded products:", sk2.map(\.id))
            for p in sk2 {
                if let sub = p.subscription {
                    let statuses = try? await sub.status
                    print("SK2 Status for \(p.id):", statuses?.map(\.state) ?? [])
                }
            }
            if !sk2.isEmpty { return } // если нашли хотя бы что-то — SK1 не нужен
        } catch {
            print("SK2 Product load error:", error)
        }

        // 3) Fallback: запрос через StoreKit 1 — покажет invalid IDs и подскажет проблему
        await SK1Debugger.fetch(ids: ids)
    }
}

/// Вспомогательный дебаггер для SK1
private enum SK1Debugger {
    private final class Delegate: NSObject, SKProductsRequestDelegate {
        let onFinish: (SKProductsResponse) -> Void
        init(onFinish: @escaping (SKProductsResponse) -> Void) { self.onFinish = onFinish }
        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            onFinish(response)
        }
        func request(_ request: SKRequest, didFailWithError error: Error) {
            print("SK1 request error:", error)
        }
    }

    static func fetch(ids: [String]) async {
        await withCheckedContinuation { cont in
            let req = SKProductsRequest(productIdentifiers: Set(ids))
            let delegate = Delegate { response in
                let ok = response.products.map { $0.productIdentifier }
                print("SK1 Loaded products:", ok)
                print("SK1 Invalid IDs:", response.invalidProductIdentifiers)
                cont.resume()
            }
            // держим делегата живым до окончания запроса
            objc_setAssociatedObject(req, Unmanaged.passUnretained(req).toOpaque(), delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            req.delegate = delegate
            req.start()
        }
    }
}

