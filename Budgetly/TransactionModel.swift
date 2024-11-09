//
//  TransactionModel.swift
//  Budgetly
//
//  Created by Виктор Корольков on 05.11.2024.
//

import Foundation
import SwiftData

@Model
class Transaction: Identifiable {
        var id: UUID
        var category: String
        var amount: Double
        var date: Date
        var type: String // Новое свойство для типа: "Доходы" или "Расходы"

    init(id: UUID, category: String, amount: Double, date: Date, type: String) {
        self.id = id
        self.category = category
        self.amount = amount
        self.date = date
        self.type = type
    }
}
