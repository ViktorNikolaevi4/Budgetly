import Foundation
import SwiftData

enum CategoryType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case expenses = "Расходы"
    case income = "Доходы"
}

@Model
class Category: Identifiable {
    var id: UUID
    var name: String
    private var typeRawValue: String
    var account: Account // Связь с конкретным счетом

    var type: CategoryType {
        get { CategoryType(rawValue: typeRawValue) ?? .expenses } // По умолчанию .expenses, если значение отсутствует
        set { typeRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(),
         name: String,
         type: CategoryType,
         account: Account
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = type.rawValue
        self.account = account
    }
}
