//
//  BudgetViewModel.swift
//  Budgetly
//
//  Created by Виктор Корольков on 05.11.2024.
//

import Foundation
import SwiftUI
import Observation

@Observable
class BudgetViewModel {
        var transactions: [Transaction] = []

        var totalExpenses: Double {
            transactions.reduce(0) { $0 + $1.amount }
        }

        func addTransaction(category: String, amount: Double) {
            let newTransaction = Transaction(id: UUID(), category: category, amount: amount, date: Date())
            transactions.append(newTransaction)
        }
}
