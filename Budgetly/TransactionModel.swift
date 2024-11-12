import Foundation
import SwiftData

enum TransactionType: Codable {
    case income, expenses
}

@Model
class Transaction: Identifiable {
    var id: UUID
    var category: String
    var amount: Double
    var date: Date
    var type: TransactionType

    init(id: UUID = UUID(), category: String, amount: Double, date: Date = Date(), type: TransactionType) {
        self.id = id
        self.category = category
        self.amount = amount
        self.date = date
        self.type = type
    }

    // Вычисляемое свойство для получения сальдо
    static func calculateSaldo(from transactions: [Transaction]) -> Double {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expenses }.reduce(0) { $0 + $1.amount }
        return income - expenses
    }
}
