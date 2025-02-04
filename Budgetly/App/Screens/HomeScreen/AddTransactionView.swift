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
                            .background(selectedType == .expenses ? Color.black : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        selectedType = .income
                    }) {
                        Text("Доходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .income ? Color.black : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
                                .background(selectedCategory == category.name ? Color.black : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
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
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .background(GradientView()) // Градиентный фон
            .scrollContentBackground(.hidden) // Убираем фон NavigationStack
       //     .navigationTitle("Добавление операции")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Добавление операции")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
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
        }.foregroundStyle(.white)
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

    // Функция для сохранения транзакции
    private func saveTransaction() {
        if let amountValue = Double(amount), let account = account {
            let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
            let newTransaction = Transaction(category: selectedCategory, amount: amountValue, type: transactionType, account: account)
            modelContext.insert(newTransaction) // Добавляем транзакцию в SwiftData
            account.transactions.append(newTransaction)
            try? modelContext.save() // Сохраняем изменения
            dismiss()
        }
    }
}

#Preview {
    AddTransactionView()
}
