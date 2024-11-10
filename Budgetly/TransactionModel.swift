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

    init(id: UUID, category: String, amount: Double, date: Date, type: TransactionType) {
        self.id = id
        self.category = category
        self.amount = amount
        self.date = date
        self.type = type
    }
}
