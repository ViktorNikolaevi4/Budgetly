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

    // Новое свойство
    var iconName: String?

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

import SwiftUI
import SwiftData

extension Category {
    static let uncategorizedName = "Без категории"

    static let defaultExpenseNames = [
        "Еда", "Транспорт", "Дом", "Одежда",
        "Здоровье", "Питомцы", "Связь", "Развлечения",
        "Образование", "Дети"
    ]
    private static let defaultIncome = [
      "Зарплата", "Подарки", "Проценты", "Продажи",
      "Премия", "Дивиденды", "Аренда", "Другое"
    ]
    static func seedDefaults(for account: Account, in context: ModelContext) {
        guard !account.hasSeededCategories else { return }

        // 1) Без категории
        let uncExp = Category(name: uncategorizedName, type: .expenses, account: account)
        let uncInc = Category(name: uncategorizedName, type: .income,   account: account)
        context.insert(uncExp)
        context.insert(uncInc)

        // 2) Расходы
        for name in defaultExpenseNames {
            context.insert(Category(name: name, type: .expenses, account: account))
        }
        // 3) Доходы
        for name in defaultIncome {
            context.insert(Category(name: name, type: .income, account: account))
        }

        account.hasSeededCategories = true
        try? context.save()
    }
}
