import SwiftUI
import SwiftData

enum CategoryType: String {
    case expenses = "Расходы"
    case income = "Доходы"
}

@Model
class Category {
    var name: String
    private var typeRawValue: String

    var type: CategoryType {
        get { CategoryType(rawValue: typeRawValue) ?? .expenses } // По умолчанию .expenses, если значение отсутствует
        set { typeRawValue = newValue.rawValue }
    }

    init(name: String, type: CategoryType) {
        self.name = name
        self.typeRawValue = type.rawValue
    }
}

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]
    @Environment(\.dismiss) var dismiss
    @State var budgetViewModel: BudgetViewModel
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

                // Используем LazyVGrid для отображения категорий в несколько строк
                  LazyVGrid(columns: columns, spacing: 10) {
                      ForEach(filteredCategories, id: \.name) { category in
                          Button(action: {
                              selectedCategory = category.name
                          }) {
                              Text(category.name)
                                  .padding()
                                  .frame(maxWidth: .infinity)
                                  .background(selectedCategory == category.name ? Color.blue : Color.gray)
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

                Spacer()

                // Кнопка сохранения транзакции
                Button(action: {
                    saveTransaction()
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
                let category = Category(name: newCategory, type: selectedType)
                modelContext.insert(category) // Добавляем категорию в SwiftData
                selectedCategory = newCategory
                newCategory = ""
        }
    }
    // Функция для сохранения транзакции
    private func saveTransaction() {
        if let amountValue = Double(amount) {
            let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
            let newTransaction = Transaction(category: selectedCategory, amount: amountValue, type: transactionType)
            modelContext.insert(newTransaction) // Добавляем транзакцию в SwiftData
            try? modelContext.save() // Сохраняем изменения
            dismiss()
        }
    }
}

#Preview {
    AddTransactionView(budgetViewModel: BudgetViewModel())
}
