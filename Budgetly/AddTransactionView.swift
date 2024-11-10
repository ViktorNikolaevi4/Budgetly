import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @State var budgetViewModel: BudgetViewModel
    @State private var selectedType: TransactionType = .expenses
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Здоровье"
    @State private var newCategory: String = ""
    @State private var isShowingAlert = false // Флаг для отображения алерта

    // Категории для доходов и расходов
    @State private var expenseCategories = ["Здоровье", "Досуг", "Дом", "Кафе", "Образование"]
    @State private var incomeCategories = ["Зарплата", "Инвестиции", "Подарки", "Прочее"]


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
                            .cornerRadius(8)
                    }

                    Button(action: {
                        selectedType = .income
                    }) {
                        Text("Доходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .income ? Color.black : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Ввод суммы
                TextField("Введите сумму", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Выбор категории
                Text("Категории")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        let categories = selectedType == .expenses ? expenseCategories : incomeCategories
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .padding()
                                    .background(selectedCategory == category ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        // Добавить новую категорию
                        Button(action: {
                            isShowingAlert = true
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }

                Spacer()

                // Кнопка сохранения транзакции
                Button(action: {
                    if let amountValue = Double(amount) {
                        budgetViewModel.addTransaction(category: selectedCategory, amount: amountValue, type: selectedType)
                        dismiss()
                    }
                }) {
                    Text("Добавить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Добавление операции")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
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
        }
    }
    // Функция для добавления новой категории
    private func addNewCategory() {
        if !newCategory.isEmpty {
            if selectedType == .expenses {
                expenseCategories.append(newCategory)
            } else {
                incomeCategories.append(newCategory)
            }
            selectedCategory = newCategory
            newCategory = ""
        }
    }
}


#Preview {
    AddTransactionView(budgetViewModel: BudgetViewModel())
}
