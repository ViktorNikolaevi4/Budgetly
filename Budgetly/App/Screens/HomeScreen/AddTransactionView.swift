import SwiftUI
import SwiftData

struct AddTransactionView: View {
    var account: Account? // Связанный счёт

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
    // Сетка с тремя колонками
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack {
                // Выбор типа: Доход или Расход
                HStack {
                    Button(action: {
                        selectedType = .expenses
                    }) {
                        Text("Расходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .expenses ? (Color(UIColor(red: 85/255, green: 80/255, blue: 255/255, alpha: 1))) : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                    }

                    Button(action: {
                        selectedType = .income
                    }) {
                        Text("Доходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .income ? (Color(UIColor(red: 85/255, green: 80/255, blue: 255/255, alpha: 1))) : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                    }
                }
                .padding()

                // Ввод суммы
                TextField("Введите сумму", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.9)) // Серый фон с прозрачностью
                    .cornerRadius(10) // Закругленные углы
                    .foregroundColor(.white) // Цвет вводимого текста
                    .padding(.horizontal)
                // Выбор категории
                Text("Категории")
                    .font(.headline)

                // Используем LazyVGrid для отображения категорий в несколько строк
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredCategories, id: \.name) { category in
                        Button(action: {
                            selectedCategory = category.name
                        }) {
                            Text(category.name)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(selectedCategory == category.name ? (Color(UIColor(red: 85/255, green: 80/255, blue: 255/255, alpha: 1))) : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(24)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.5)
                        }
                        // Добавляем контекстное меню для удаления
                        .contextMenu {
                            Button(role: .destructive) {
                                removeCategory(category)
                            } label: {
                                Label("Удалить категорию", systemImage: "trash")
                            }
                        }
                    }
                    // Добавить новую категорию
                    Button(action: {
                        isShowingAlert = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.largeTitle)
                           //  bold()
                            .foregroundColor(.black)
                    }
                }
                .padding()

                Spacer()

                // Кнопка сохранения транзакции
                Button(action: {
                    saveTransaction()
                }) {
                    Text("Добавить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((Color(UIColor(red: 85/255, green: 80/255, blue: 255/255, alpha: 1))))
                        .foregroundColor(.white)
                        .cornerRadius(24)
                }
                .padding()
            }
            .background(GradientView()) // Градиентный фон
            .scrollContentBackground(.hidden) // Убираем фон NavigationStack
       //     .navigationTitle("Добавление операции")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Добавление операции")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                    }
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
        // Текущая дата или дата, выбранная пользователем
        let newTransactionDate = Date()
        // Если пользователь выбирает дату вручную — подставьте её вместо Date()
        let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
        // Ищем существующую транзакцию, у которой:
        // 1) такая же категория
        // 2) такой же тип (доход/расход)
        // 3) дата совпадает по дню
        if let existingTransaction = account.transactions.first(where: { transaction in
            transaction.category == selectedCategory &&
            transaction.type == transactionType &&
            Calendar.current.isDate(transaction.date, inSameDayAs: newTransactionDate)
        }) {
            // Если нашли, то увеличиваем её сумму
            existingTransaction.amount += amountValue
        } else {
            // Иначе создаём новую
            let newTransaction = Transaction(
                category: selectedCategory,
                amount: amountValue,
                type: transactionType,
                account: account
            )
            // Не забудьте сохранить дату
            newTransaction.date = newTransactionDate

            modelContext.insert(newTransaction)
            account.transactions.append(newTransaction)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
}

#Preview {
    AddTransactionView()
}
