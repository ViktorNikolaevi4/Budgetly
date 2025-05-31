import Foundation
import SwiftData

@Model
class Account: Identifiable {
    var id: UUID
    var name: String
    /// Опциональное поле «Начальный баланс»
    var initialBalance: Double?

    /// Опциональное поле «Валюта»
    var currency: String?

    var hasSeededCategories: Bool = false
    var transactions: [Transaction] = []
    var categories: [Category] = []

    init(
        id: UUID = UUID(),
        name: String,
        currency: String? = nil,
        initialBalance: Double? = nil,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.initialBalance = initialBalance
        self.transactions = transactions
    }

    /// Баланс считается как: (initialBalance ?? 0) + все «доходы» - все «расходы»
    var balance: Double {
        let base = initialBalance ?? 0

        let income = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.type == .expenses }
            .reduce(0) { $0 + $1.amount }

        return base + income - expenses
    }

    /// Форматированный баланс: «100 000 ₽» или «123.45 USD»
    var formattedBalance: String {
        let amountString = "\(balance.toShortStringWithSuffix())"
        // Если валюты нет, подставляем «RUB»
        let cur = currency ?? "RUB"
        return "\(amountString) \(cur)"
    }
}



