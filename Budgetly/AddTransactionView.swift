//
//  AddTransactionView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 05.11.2024.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @State var budgetViewModel: BudgetViewModel
    @State private var selectedType: String = "Расходы"
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Здоровье"
    @State private var newCategory: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                // Выбор типа: Доход или Расход
                HStack {
                    Button(action: {
                        selectedType = "Расходы"
                    }) {
                        Text("Расходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == "Расходы" ? Color.black : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        selectedType = "Доходы"
                    }) {
                        Text("Доходы")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == "Доходы" ? Color.black : Color.gray)
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
                        ForEach(["Здоровье", "Досуг", "Дом", "Кафе", "Образование", "Подарки", "Продукты"], id: \.self) { category in
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
                            // Открытие формы добавления новой категории
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
                        budgetViewModel.addTransaction(category: selectedCategory, amount: amountValue)
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
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}


#Preview {
    AddTransactionView(budgetViewModel: BudgetViewModel())
}
