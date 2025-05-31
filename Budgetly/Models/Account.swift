import Foundation
import SwiftData

@Model
class Account: Identifiable {
    var id: UUID
    var name: String
    var hasSeededCategories: Bool = false
    var transactions: [Transaction] = []
    var categories: [Category] = []

    init(id: UUID = UUID(),
         name: String,
         transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.transactions = transactions
    }

    // Рассчитываем баланс счёта на основе транзакций
    var balance: Double {
        let income = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.type == .expenses }
            .reduce(0) { $0 + $1.amount }

        return income - expenses
    }

    // Форматированный баланс для отображения
    var formattedBalance: String {
        return "\(balance.toShortStringWithSuffix()) ₽"
    }
}
