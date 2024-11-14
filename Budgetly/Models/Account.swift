//
//  Account.swift
//  Budgetly
//
//  Created by Виктор Корольков on 14.11.2024.
//
import Foundation
import SwiftData

@Model
class Account: Identifiable {
    var id: UUID
    var name: String
    var transactions: [Transaction] = []
    var categories: [Category] = []

    init(id: UUID = UUID(), name: String, transactions: [Transaction] = []) {
        self.id = id
        self.name = name
        self.transactions = transactions
    }
}
