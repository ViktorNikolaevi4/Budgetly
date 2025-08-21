import StoreKit
import SwiftUI
import Observation

@MainActor
@Observable
final class StoreService {
    var isPremium = false
    private(set) var monthlyProduct: Product?
    private(set) var yearlyProduct: Product?
    private var updatesTask: Task<Void, Never>?
 //   let trialManager = AppTrialManager()

    init() {
        // Слушатель апдейтов транзакций
        updatesTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await withTaskCancellationHandler {
                await self.observeTransactionUpdates()
            } onCancel: { [weak self] in
                Task { @MainActor in self?.updatesTask = nil }
            }
        }

        // Первая загрузка + первичная проверка статуса
        Task { @MainActor [weak self] in
            await self?.loadProductsAndCheckStatus()
            await self?.refreshPremiumStatus()   // ← важный вызов
        }
    }

    func cancelTasks() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    func loadProductsAndCheckStatus() async {
        do {
            let ids = ["com.budgetly.premium.monthly", "com.budgetly.premium.yearly"]
            let products = try await Product.products(for: ids)
            print("Загруженные продукты SK2: \(products.map(\.id))")
            monthlyProduct = products.first { $0.id == ids[0] }
            yearlyProduct  = products.first { $0.id == ids[1] }
        } catch {
            print("Ошибка загрузки продуктов SK2: \(error)")
        }
    }

    // Публичная проверка — вызывать отовсюду
    func refreshPremiumStatus() async {
        var active  = false
        var inGrace = false

        // 1) Проверка по текущим энтайтлментам (без привязки к продуктам)
        for await ent in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let tx) = ent, tx.productType == .autoRenewable else { continue }
            let notRevoked = (tx.revocationDate == nil)
            let notExpired = (tx.expirationDate?.timeIntervalSinceNow ?? Double.infinity) > 0
            if notRevoked && notExpired { active = true }
        }

        // 2) Статусы подписки у самих продуктов (даёт .inGracePeriod / .inBillingRetryPeriod)
        let products = [monthlyProduct, yearlyProduct].compactMap { $0 }   // что успели загрузить
        for p in products {
            guard let sub = p.subscription else { continue }
            do {
                let statuses = try await sub.status
                for status in statuses {
                    switch status.state {
                    case .subscribed:
                        active = true
                    case .inGracePeriod, .inBillingRetryPeriod:
                        inGrace = true
                    default:
                        break
                    }

                    // Дополнительная проверка транзакции (на всякий)
                    if case .verified(let tx) = status.transaction,
                       tx.revocationDate == nil,
                       (tx.expirationDate?.timeIntervalSinceNow ?? Double.infinity) > 0 {
                        active = true
                    }
                }
            } catch {
                print("status error:", error)
            }
        }

        isPremium = active || inGrace
    //    if isPremium { trialManager.markAsSubscribed() }
    }

    // Слушаем поток и при любом апдейте — обновляем флаг
    private func observeTransactionUpdates() async {
        for await result in StoreKit.Transaction.updates {
            guard case .verified(let tx) = result else { continue }
            await tx.finish()
            await refreshPremiumStatus()
        }
    }

    func restorePurchases() async {
        do { try await AppStore.sync() } catch { print("restore error:", error) }
        await refreshPremiumStatus()
    }
}
