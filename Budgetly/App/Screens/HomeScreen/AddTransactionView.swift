import SwiftUI
import SwiftData

struct AddTransactionView: View {
    var account: Account? // Связанный счёт
    var onTransactionAdded: ((TransactionType) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: CategoryType = .expenses
    @State private var amount: String = ""
    @FocusState private var isAmountFieldFocused: Bool
    @State private var selectedCategory: String = Category.uncategorizedName
    @State private var newCategory: String = ""
    @State private var isShowingAlert = false // Флаг для отображения алерта
    @State private var hasEnsuredCategories = false

    private var categoriesForThisAccount: [Category] {
        guard let acct = account else { return [] }
        return allCategories.filter { $0.account.id == acct.id }
    }

    private var filteredCategories: [Category] {
        categoriesForThisAccount
            .filter { $0.type == selectedType }
            .sorted { lhs, rhs in
                if lhs.name == Category.uncategorizedName { return true }
                if rhs.name == Category.uncategorizedName { return false }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
    }
    
    struct FlowLayout: Layout {
        var spacing: CGFloat = 10

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            var totalHeight: CGFloat = 0
            var totalWidth: CGFloat = 0
            var lineWidth: CGFloat = 0
            var lineHeight: CGFloat = 0

            for size in sizes {
                if lineWidth + size.width > (proposal.width ?? 0) && lineWidth > 0 {
                    totalWidth = max(totalWidth, lineWidth)
                    totalHeight += lineHeight + spacing
                    lineWidth = 0
                    lineHeight = 0
                }
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            totalWidth = max(totalWidth, lineWidth)
            totalHeight += lineHeight

            return CGSize(width: max(totalWidth - spacing, 0), height: totalHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            var lineWidth: CGFloat = 0
            var lineHeight: CGFloat = 0
            var y: CGFloat = bounds.minY
            var x: CGFloat = bounds.minX

            for (index, subview) in subviews.enumerated() {
                let size = sizes[index]

                if lineWidth + size.width > bounds.width && lineWidth > 0 {
                    x = bounds.minX
                    y += lineHeight + spacing
                    lineWidth = 0
                    lineHeight = 0
                }

                subview.place(
                    at: CGPoint(x: x, y: y + (size.height / 2)),
                    anchor: .leading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )

                x += size.width + spacing
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Выбор «расходы / доходы»
                Picker("Тип операции", selection: $selectedType) {
                    Text("Расходы").tag(CategoryType.expenses)
                    Text("Доходы").tag(CategoryType.income)
                }
                .pickerStyle(.segmented)
                .tint(.appPurple)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 4)
                        // Ввод суммы
                        TextField("Введите сумму", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.white) // Серый фон с прозрачностью
                            .cornerRadius(10) // Закругленные углы
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isAmountFieldFocused ? Color.appPurple : .clear, lineWidth: 2)
                            )
                            .focused($isAmountFieldFocused)
                            .foregroundColor(.black) // Цвет вводимого текста
                            .padding(.horizontal)
                        //    .focused($isAmountFieldFocused)
//                HStack {
//                        // Выбор категории
//                        Text("Категории")
//                            .font(.headline)
//                   Spacer()
//                    Button {
//                        isShowingAlert = true
//                    } label: {
//                        Image(systemName: "plus.circle")
//                            .font(.title)
//                            .foregroundStyle(.black)
//                    }
//                }
                ScrollView {
                    FlowLayout(spacing: 10) {
                        ForEach(filteredCategories, id: \.name) { category in
                            Button {
                                selectedCategory = category.name
                            } label: {
                                CategoryBadge(category: category, isSelected: selectedCategory == category.name)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeCategory(category)
                                } label: {
                                    Label("Удалить категорию", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                // Кнопка сохранения транзакции
                        Button("Добавить") {
                            saveTransaction()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.appPurple)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
            }
            .background(Color("BackgroundLightGray")) // фон
            .scrollContentBackground(.hidden) // Убираем фон NavigationStack
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Новая операция")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                }
                // кнопка «Отменить»
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отменить") { dismiss() }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
                // 🚀 новая кнопка «Добавить» для создания категории
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить") { isShowingAlert = true }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
            }
            // Алерт для добавления новой категории
            .alert("Новая категория", isPresented: $isShowingAlert) {
                TextField("Введите новую категорию", text: $newCategory)
                Button("Добавить", action: {
                    addNewCategory()
                })
                Button("Отмена", role: .cancel, action: {
                    newCategory = ""
                })
            }
        }
        .foregroundStyle(.black)
        .onAppear {
            DispatchQueue.main.async {
                isAmountFieldFocused = true

            }
        }
    }

    // Функция для добавления новой категории
    private func addNewCategory() {
        guard let account = account, !newCategory.isEmpty else {
            // Можно добавить сообщение об ошибке или лог для отладки
            print("Ошибка: отсутствует account или пустое имя категории")
            return
        }
        let category = Category(name: newCategory, type: selectedType, account: account)
        modelContext.insert(category) // Добавляем категорию в SwiftData
        selectedCategory = newCategory
        newCategory = ""

        // Сохранение изменений
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении категории: \(error)")
        }
    }
    // Функция для удаления категории
    private func removeCategory(_ category: Category) {
        guard let account = account else { return }

        // 1. Находим все транзакции, у которых `transaction.category` совпадает с именем удаляемой категории
        let transactionsToRemove = account.transactions.filter { $0.category == category.name }

        // 2. Удаляем все эти транзакции из modelContext
        for transaction in transactionsToRemove {
            modelContext.delete(transaction)
        }

        // 3. Теперь удаляем саму категорию
        modelContext.delete(category)

        // 4. Сохраняем изменения
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении категории: \(error)")
        }
    }
    
    // Функция для сохранения транзакции
    private func saveTransaction() {
        guard
            let account = account,
            let amountValue = Double(amount),
            !selectedCategory.isEmpty
        else {
            return
        }
        // Дата транзакции (по умолчанию текущая)
        let newTransactionDate = Date()
        // Определяем тип (расход/доход)
        let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
        // Создаём новую транзакцию, не пытаясь искать существующую и не суммируя
        let newTransaction = Transaction(
            category: selectedCategory,
            amount: amountValue,
            type: transactionType,
            account: account
        )
        newTransaction.date = newTransactionDate
        // Добавляем в контекст и в массив транзакций счёта
        modelContext.insert(newTransaction)
        account.transactions.append(newTransaction)
        // Сохраняем
        do {
            try modelContext.save()
            onTransactionAdded?(transactionType)
            dismiss() // Закрываем текущий экран
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
}

struct CategoryBadge: View {
    let category: Category
    let isSelected: Bool

    private static let badgeWidth: CGFloat = 84.3
    private static let badgeHeight: CGFloat = 68

    var body: some View {
        VStack(spacing: 4) {
            Text(category.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(width: Self.badgeWidth, height: Self.badgeHeight)
        .background(Color.white) // Фон всегда белый
        .foregroundColor(.black) // Текст чёрный
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.appPurple : .clear, lineWidth: 2) // Обводка только для выбранной категории
        )
    }
}

