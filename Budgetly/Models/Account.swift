
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
}
