//
//  RegularPayment.swift
//  Budgetly
//
//  Created by Виктор Корольков on 14.11.2024.
//

import Foundation
import SwiftData

@Model
class RegularPayment: Identifiable {
    var id: UUID
    var name: String
    var frequency: String
    var startDate: Date
    var endDate: Date?
    var amount: Double
    var comment: String

    init(id: UUID = UUID(), name: String, frequency: String, startDate: Date, endDate: Date?, amount: Double, comment: String) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.amount = amount
        self.comment = comment
    }
}
