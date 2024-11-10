import SwiftUI
import Charts
import Observation

struct ContentView: View {
    @State private var budgetViewModel = BudgetViewModel()
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var isMenuVisible = false // Управляет отображением меню
    @State private var selectedTimePeriod: String = "Все время" // Выбранный временной диапазон

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    // Отображение сальдо
                    Text("Сальдо: \(budgetViewModel.saldo, specifier: "%.2g") ₽")
                        .foregroundStyle(budgetViewModel.totalExpenses >= budgetViewModel.totalIncome ? .green : .red)
                        .font(.title2)
                        .padding()
                    // Переключатель между доходами и расходами
                    HStack {
                        Button(action: {
                            selectedTransactionType = .expenses
                        }) {
                            Text("Расходы")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTransactionType == .expenses ? Color.black : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            selectedTransactionType = .income
                        }) {
                            Text("Доходы")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTransactionType == .income ? Color.black : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    // Переключатель временного диапазона
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(["День", "Неделя", "Месяц", "Год", "Все время"], id: \.self) { period in
                                Button(action: {
                                    selectedTimePeriod = period
                                }) {
                                    Text(period)
                                        .font(.caption)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 8)
                                        .background(selectedTimePeriod == period ? Color.blue : Color.gray)
                                        .foregroundStyle(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Диаграмма расходов или доходов на основе выбранного типа
                    PieChartView(transactions: budgetViewModel.transactions.filter { $0.type == selectedTransactionType })

                    // Список транзакций, отфильтрованный по выбранному типу
                    List {
                        ForEach(filteredTransactions) { transaction in
                            HStack {
                                Text(transaction.category)
                                Spacer()
                                Text("\(transaction.amount, specifier: "%.2f") ₽")
                                    .foregroundColor(selectedTransactionType == .expenses ? .red : .green)
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
    // Фильтруем транзакции по типу и времени
    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return budgetViewModel.transactions.filter { transaction in
            // Фильтрация по типу
            guard transaction.type == selectedTransactionType else { return false }

            // Фильтрация по выбранному временному диапазону
            switch selectedTimePeriod {
            case "День":
                return calendar.isDateInToday(transaction.date)
            case "Неделя":
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case "Месяц":
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case "Год":
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            default:
                return true // "Все время" показывает все транзакции
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
            .frame(width: 350) // Ширина меню
            .background(Color.white)
            .offset(x: isMenuVisible ? 0 : -250) // Выдвижение меню
            .animation(.easeInOut(duration: 0.3), value: isMenuVisible)
        }
    }
}
