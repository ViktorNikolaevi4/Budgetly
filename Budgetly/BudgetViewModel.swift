import Foundation
import SwiftUI
import Observation

// Ваша модель BudgetViewModel
@Observable
class BudgetViewModel{
    var accounts: [Account] = [Account(name: "Основной счет")]
    
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

    func addTransaction(category: String, amount: Double, type: TransactionType, account: Account) {
        let newTransaction = Transaction(id: UUID(), category: category, amount: amount, date: Date(), type: type, account: account)
        transactions.append(newTransaction)
        account.transactions.append(newTransaction) // Добавляем транзакцию в аккаунт

    }
}
