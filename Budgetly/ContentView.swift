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
    @State private var selectedTransactionType: String = "Расходы" // Переключатель между "Доходы" и "Расходы"
    @State private var isMenuVisible = false // Управляет отображением меню
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    // Переключатель между доходами и расходами
                    HStack {
                        Button(action: {
                            selectedTransactionType = "Расходы"
                        }) {
                            Text("Расходы")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTransactionType == "Расходы" ? Color.black : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            selectedTransactionType = "Доходы"
                        }) {
                            Text("Доходы")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTransactionType == "Доходы" ? Color.black : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    // Диаграмма расходов или доходов на основе выбранного типа
                    PieChartView(transactions: budgetViewModel.transactions.filter { $0.type == selectedTransactionType })
                    
                    // Список транзакций, отфильтрованный по выбранному типу
                    List {
                        ForEach(budgetViewModel.transactions.filter { $0.type == selectedTransactionType }) { transaction in
                            HStack {
                                Text(transaction.category)
                                Spacer()
                                Text("\(transaction.amount, specifier: "%.2f") ₽")
                                    .foregroundColor(selectedTransactionType == "Расходы" ? .red : .green)
                            }
                        }
                    }
                    
                    // Кнопка добавления транзакции
                    Button(action: {
                        isAddTransactionViewPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
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
                            // Показать/скрыть меню
                            withAnimation {
                                isMenuVisible.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
            // Выдвигающееся меню
            if isMenuVisible {
                SideMenuView(isMenuVisible: $isMenuVisible)
            }
        }
    }
}

#Preview {
    ContentView()
}

// Представление для меню
struct SideMenuView: View {
    @Binding var isMenuVisible: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Полупрозрачный фон для скрытия меню при нажатии за его пределами
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isMenuVisible.toggle()
                    }
                }

            // Само меню
            VStack(alignment: .leading) {
                Text("Главная")
                    .padding()
                Text("Счета")
                    .padding()
                Text("Графики")
                    .padding()
                Text("Категории")
                    .padding()
                Text("Регулярные платежи")
                    .padding()
                Text("Напоминания")
                    .padding()
                Text("Настройки")
                    .padding()
                Text("Поделиться с друзьями")
                    .padding()
                Text("Оценить приложение")
                    .padding()
                Text("Связь с разработчиком")
                    .padding()

                Spacer()
            }
            .frame(width: 250) // Ширина меню
            .background(Color.white)
            .offset(x: isMenuVisible ? 0 : -250) // Выдвижение меню
            .animation(.easeInOut(duration: 0.3), value: isMenuVisible)
        }
    }
}
