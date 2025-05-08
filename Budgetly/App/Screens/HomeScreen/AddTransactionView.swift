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
    @State private var selectedCategory: String = "Здоровье"
    @State private var newCategory: String = ""
    @State private var isShowingAlert = false // Флаг для отображения алерта

    // Категории для доходов и расходов
    var filteredCategories: [Category] {
        allCategories.filter { $0.type == selectedType }
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

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
                .padding(.horizontal)
                .padding(.top)
                        // Ввод суммы
                        TextField("Введите сумму", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.gray.opacity(0.3)) // Серый фон с прозрачностью
                            .cornerRadius(10) // Закругленные углы
                            .foregroundColor(.black) // Цвет вводимого текста
                            .padding(.horizontal)
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
                    // Используем LazyVGrid для отображения категорий в несколько строк
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredCategories, id: \.name) { category in
                            Button {
                                selectedCategory = category.name
                            } label: {
                                Text(category.name)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8) // слегка сжимать, если всё‑таки не помещается
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity) // растянуться на ширину столбца
                                    .background(selectedCategory == category.name
                                                ? Color.appPurple
                                                : Color.gray.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                             .contextMenu {
                                Button(role: .destructive) {
                                    removeCategory(category)
                                 } label: {
                                    Label("Удалить категорию", systemImage: "trash")
                              }
                           }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
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
        }.foregroundStyle(.black)
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
