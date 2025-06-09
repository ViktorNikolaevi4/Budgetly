import Foundation
import SwiftData

@Model
class Account: Identifiable {
    var id: UUID
    var name: String
    /// Опциональное поле «Начальный баланс»
    var initialBalance: Double?
    /// Опциональное поле «Валюта»
    var currency: String?
    var hasSeededCategories: Bool = false
    var isHidden: Bool = false

    @Attribute var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade)
    var categories: [Category] = []

    init(
        id: UUID = UUID(),
        name: String,
        currency: String? = nil,
        initialBalance: Double? = nil,
        sortOrder: Int = 0,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.initialBalance = initialBalance
        self.transactions = transactions
        self.sortOrder = sortOrder
    }

    /// Баланс считается как: (initialBalance ?? 0) + все «доходы» - все «расходы»
    var balance: Double {
        let base = initialBalance ?? 0

        let income = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.type == .expenses }
            .reduce(0) { $0 + $1.amount }

        return base + income - expenses
    }

    /// Форматированный баланс: «100 000 ₽» или «123.45 USD»
    var formattedBalance: String {
        let amountString = "\(balance.toShortStringWithSuffix())"
        // Если валюты нет, подставляем «RUB»
        let cur = currency ?? "RUB"
        return "\(amountString) \(cur)"
    }
}
enum TransactionType: Codable {
    case income, expenses
}

@Model
class Transaction: Identifiable {
    var id: UUID
    var category: String
    var amount: Double
    var date: Date
    var type: TransactionType

    @Relationship(inverse: \Account.transactions)
    var account: Account? // Связь с конкретным счетом

    init(id: UUID = UUID(),
         category: String,
         amount: Double,
         date: Date = Date(),
         type: TransactionType,
         account: Account
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.date = date
        self.type = type
        self.account = account
    }

    // Вычисляемое свойство для получения сальдо
    static func calculateSaldo(from transactions: [Transaction]) -> Double {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expenses }.reduce(0) { $0 + $1.amount }
        return income - expenses
    }
}


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

    @Relationship(inverse: \Account.categories)
    var account: Account?

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
     static let defaultIncomeNames = [
      "Зарплата", "Дивиденды", "Купоны", "Продажи",
      "Премия", "Вклады", "Аренда", "Подарки", "Подработка"
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
        for name in defaultIncomeNames {
            context.insert(Category(name: name, type: .income, account: account))
        }

        account.hasSeededCategories = true
        try? context.save()
    }
}
