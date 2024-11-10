import Foundation
import SwiftUI
import Observation

// Ваша модель BudgetViewModel
@Observable
class BudgetViewModel {
    var transactions: [Transaction] = []

    var totalExpenses: Double {
        transactions.filter { $0.type == .expenses }.reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var saldo: Double {
        totalIncome - totalExpenses
    }

    func addTransaction(category: String, amount: Double, type: TransactionType) {
        let newTransaction = Transaction(id: UUID(), category: category, amount: amount, date: Date(), type: type)
        transactions.append(newTransaction)
    }
}
