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

extension Category {
    static let uncategorizedName = "Без категории"
    static func ensureUncategorized(for account: Account, in context: ModelContext) {
    guard !account.hasSeededCategories else { return }
    // создаём нужные две категории
    context.insert(Category(name: uncategorizedName, type: .expenses, account: account))
    context.insert(Category(name: uncategorizedName, type: .income,   account: account))
    account.hasSeededCategories = true
    try? context.save()
  }
}

