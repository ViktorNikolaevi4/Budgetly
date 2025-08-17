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
    let trialManager = AppTrialManager()

    init() {
        // Слушаем обновления транзакций (контекст MainActor)
        updatesTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await withTaskCancellationHandler {
                await self.observeTransactionUpdates()
            } onCancel: { [weak self] in
                // onCancel nonisolated -> переходим на MainActor отдельной задачей
                Task { @MainActor in
                    self?.updatesTask = nil
                }
            }
        }

        // Первая загрузка продуктов и проверка статуса
        Task { @MainActor [weak self] in
            await self?.loadProductsAndCheckStatus()
        }
    }

//
//    deinit {
//        updatesTask?.cancel()
//        updatesTask = nil
//    }

    func cancelTasks() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    func loadProductsAndCheckStatus() async {
        do {
            let ids = ["com.budgetly.premium.monthly", "com.budgetly.premium.yearly"]
            let products = try await Product.products(for: ids)
            monthlyProduct = products.first { $0.id == "com.budgetly.premium.monthly" }
            yearlyProduct = products.first { $0.id == "com.budgetly.premium.yearly" }
            await updatePremiumStatus()
        } catch {
            print("Ошибка загрузки продуктов: \(error)")
        }
    }

    func refreshPremiumStatus() async {
            await updatePremiumStatus()
        }

    private func updatePremiumStatus() async {
        isPremium = false
        for await result in StoreKit.Transaction.updates {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewable && transaction.revocationDate == nil {
                    isPremium = true
                    trialManager.markAsSubscribed()
                    break
                }
            case .unverified(_, _):
                continue
            }
        }
    }

    private func observeTransactionUpdates() async {
        for await result in StoreKit.Transaction.updates {
            await updatePremiumStatus()
        }
    }

    func restorePurchases() async {
        await updatePremiumStatus()
    }
}
