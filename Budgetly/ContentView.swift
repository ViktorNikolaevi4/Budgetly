import SwiftUI
import Charts
import Observation
import SwiftData

enum SelectedView {
    case contentView
    case accounts
    case charts
    case categories
    // Добавьте другие представления, если нужно
}

struct ContentView: View {
    @Query private var transactions: [Transaction]
    @State private var budgetViewModel = BudgetViewModel()
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var isMenuVisible = false // Управляет отображением меню
    @State private var selectedTimePeriod: String = "Все время" // Выбранный временной диапазон
    @State private var selectedView: SelectedView = .contentView // Состояние для отображения текущего представления

    // Вычисляемое свойство для расчёта сальдо
    private var saldo: Double {
        Transaction.calculateSaldo(from: transactions)
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if selectedView == .contentView {
                        mainContentView // Отображаем главное представление
                    } else {
                        Text("Другие представления") // Здесь могут быть другие представления для других пунктов меню
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
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
            // Отображение бокового меню
            if isMenuVisible {
                SideMenuView(isMenuVisible: $isMenuVisible, selectedView: $selectedView)
            }
        }
    }

    // Основное содержимое ContentView
    private var mainContentView: some View {
        VStack {
            Text("Сальдо: \(saldo >= 0 ? "+" : "")\(saldo, specifier: "%.2f") ₽")
                .foregroundColor(saldo >= 0 ? .green : .red)
                .font(.title2)
                .padding()

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(["День", "Неделя", "Месяц", "Год", "Все время"], id: \.self) { period in
                        Button(action: {
                            selectedTimePeriod = period
                        }) {
                            Text(period)
                                .font(.caption)
                                .frame(width:55, height: 5)
                                .padding()
                                .background(selectedTimePeriod == period ? Color.blue : Color.gray)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            PieChartView(transactions: transactions.filter { $0.type == selectedTransactionType })

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
    }

    // Фильтруем транзакции по типу и времени
    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return transactions.filter { transaction in
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


struct SideMenuView: View {
    @Binding var isMenuVisible: Bool
    @Binding var selectedView: SelectedView // Привязка для изменения текущего представления

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
                Button("Главная") {
                    withAnimation {
                        selectedView = .contentView // Устанавливаем главное представление
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Счета") {
                    withAnimation {
                        selectedView = .accounts // Устанавливаем отображение "Счета"
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Графики") {
                    withAnimation {
                        selectedView = .charts // Устанавливаем отображение "Графики"
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Категории") {
                    withAnimation {
                        selectedView = .categories // Устанавливаем отображение "Категории"
                        isMenuVisible = false
                    }
                }
                .padding()

                // Добавьте остальные кнопки меню

                Spacer()
            }
            .frame(width: 250) // Ширина меню
            .background(Color.white)
            .offset(x: isMenuVisible ? 0 : -250) // Выдвижение меню
            .animation(.easeInOut(duration: 0.3), value: isMenuVisible)
        }
    }
}
