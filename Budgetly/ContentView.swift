//
//  ContentView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 05.11.2024.
//

import SwiftUI
import Charts
import Observation

struct ContentView: View {
    @State private var budgetViewModel = BudgetViewModel()
    @State private var isAddTransactionViewPresented = false

    var body: some View {
        NavigationStack {
            VStack {
                // Диаграмма расходов
                PieChartView(transactions: budgetViewModel.transactions)

                // Список транзакций
                List {
                    ForEach(budgetViewModel.transactions) { transaction in
                        HStack {
                            Text(transaction.category)
                            Spacer()
                            Text("\(transaction.amount, specifier: "%.2f") ₽")
                                .foregroundColor(.red)
                        }
                    }
                }

                // Кнопка добавления транзакции
                Button(action: {
                    isAddTransactionViewPresented = true
                }) {
                    Image(systemName: "plus.circle.fill")
                     //   .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .font(.largeTitle)
                }
                .padding()
                .sheet(isPresented: $isAddTransactionViewPresented) {
                            AddTransactionView(budgetViewModel: budgetViewModel)
                        }
            }
            .toolbar {
                // Добавляем кнопку шестеренки в верхний левый угол
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Действие при нажатии на кнопку
                        print("Настройки нажаты")
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.black)
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
