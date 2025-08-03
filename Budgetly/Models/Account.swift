import Foundation
import SwiftData

@Model
class Account: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var initialBalance: Double? = nil
    var currency: String? = nil
    var hasSeededCategories: Bool = false
    var isHidden: Bool = false

    @Attribute var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]? // Опциональный массив

    @Relationship(deleteRule: .cascade)
    var categories: [Category]? // Опциональный массив

    @Relationship(deleteRule: .cascade)
    var regularPayments: [RegularPayment]? // Опциональный массив

    var allTransactions: [Transaction] {
        transactions ?? []
    }

    var allCategories: [Category] {
        categories ?? []
    }

    var allRegularPayments: [RegularPayment] {
        regularPayments ?? []
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        currency: String? = nil,
        initialBalance: Double? = nil,
        sortOrder: Int = 0,
        transactions: [Transaction]? = nil,
        categories: [Category]? = nil,
        regularPayments: [RegularPayment]? = nil
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.initialBalance = initialBalance
        self.sortOrder = sortOrder
        self.transactions = transactions
        self.categories = categories
        self.regularPayments = regularPayments
    }

    var balance: Double {
        let base = initialBalance ?? 0
        let income = allTransactions.filter { $0.type == .income }.reduce(0) { $0 + ($1.amount) }
        let expenses = allTransactions.filter { $0.type == .expenses }.reduce(0) { $0 + ($1.amount) }
        return base + income - expenses
    }

    var formattedBalance: String {
        let amount = balance.toShortStringWithSuffix()
        let code = currency ?? "RUB"
        let sign = currencySymbols[code] ?? code
        return "\(amount) \(sign)"
    }
}
enum TransactionType: Codable {
    case income, expenses
}

@Model
class Transaction: Identifiable {
    var id: UUID = UUID()
    var category: String = ""
    var amount: Double = 0.0
    var date: Date = Date()
    var type: TransactionType = TransactionType.income

    @Relationship(inverse: \Account.transactions)
    var account: Account?

    init(
        id: UUID = UUID(),
        category: String = "",
        amount: Double = 0.0,
        date: Date = Date(),
        type: TransactionType = .income,
        account: Account? = nil
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.date = date
        self.type = type
        self.account = account
    }

    static func calculateSaldo(from transactions: [Transaction]?) -> Double {
        let income = transactions?.filter { $0.type == .income }.reduce(0) { $0 + ($1.amount) } ?? 0
        let expenses = transactions?.filter { $0.type == .expenses }.reduce(0) { $0 + ($1.amount) } ?? 0
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
    var id: UUID = UUID() // Значение по умолчанию
    var name: String = "" // Значение по умолчанию
    private var typeRawValue: String = CategoryType.expenses.rawValue // Значение по умолчанию

    @Relationship(inverse: \Account.categories)
    var account: Account? // Обратная связь

    var iconName: String? = nil

    var type: CategoryType {
        get { CategoryType(rawValue: typeRawValue) ?? .expenses }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        type: CategoryType = .expenses,
        account: Account? = nil
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
extension Account {
    var currencyCode: String { currency ?? "RUB" }
}
