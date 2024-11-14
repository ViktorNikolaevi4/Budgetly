import SwiftUI
import Charts
import Observation
import SwiftData

enum SelectedView {
    case contentView
    case accounts
    case regularPayments
    case reminders
    case settings
    case shareWithFriends
    case appEvaluation
    case contacTheDeveloper
    // Добавьте другие представления, если нужно
}

struct ContentView: View {
    @State private var selectedAccount: Account?
    @Query private var transactions: [Transaction]
    @State private var budgetViewModel = BudgetViewModel()
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: String = "Все время"
    @State private var selectedView: SelectedView = .contentView
    @State private var isMenuVisible = false

    private var saldo: Double {
        guard let account = selectedAccount else { return 0 }
        let income = account.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = account.transactions.filter { $0.type == .expenses }.reduce(0) { $0 + $1.amount }
        return income - expenses
    }

    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return (selectedAccount?.transactions ?? []).filter { transaction in
            guard transaction.type == selectedTransactionType else { return false }
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
                return true
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if selectedView == .contentView {
                        mainContentView
                    } else if selectedView == .accounts {
                        AccountsView(budgetViewModel: budgetViewModel)
                    }
                }
                .navigationTitle("Бюджет")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            withAnimation {
                                isMenuVisible.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                    }
                }
            }

            if isMenuVisible {
                SideMenuView(isMenuVisible: $isMenuVisible, selectedView: $selectedView)
            }
        }
    }

    private var mainContentView: some View {
        VStack {
            Picker("Выберите счет", selection: $selectedAccount) {
                ForEach(budgetViewModel.accounts) { account in
                    Text(account.name).tag(account as Account?)
                }
            }
            .padding()
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = budgetViewModel.accounts.first
                }
            }

            Text("Сальдо: \(saldo >= 0 ? "+" : "")\(saldo, specifier: "%.2f") ₽")
                .foregroundColor(saldo >= 0 ? .green : .red)
                .font(.title2)
                .padding()

            HStack {
                Button(action: { selectedTransactionType = .expenses }) {
                    Text("Расходы")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTransactionType == .expenses ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: { selectedTransactionType = .income }) {
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
                        Button(action: { selectedTimePeriod = period }) {
                            Text(period)
                                .font(.caption)
                                .frame(width: 55, height: 5)
                                .padding()
                                .background(selectedTimePeriod == period ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.bottom) // Отступ перед графиком

            PieChartView(transactions: filteredTransactions) // Перемещен ниже

            List(filteredTransactions) { transaction in
                HStack {
                    Text(transaction.category)
                    Spacer()
                    Text("\(transaction.amount, specifier: "%.2f") ₽")
                        .foregroundColor(transaction.type == .expenses ? .red : .green)
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
                AddTransactionView(account: selectedAccount, budgetViewModel: budgetViewModel)
            }
        }
    }}

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

                Button("Регулярные платежи") {
                    withAnimation {
                        selectedView = .regularPayments
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Напоминания") {
                    withAnimation {
                        selectedView = .reminders
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Настройки") {
                    withAnimation {
                        selectedView = .settings
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Поделиться с друзьями") {
                    withAnimation {
                        selectedView = .shareWithFriends
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Оценить приложение") {
                    withAnimation {
                        selectedView = .appEvaluation
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Связаться с разработчикамм") {
                    withAnimation {
                        selectedView = .contacTheDeveloper
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
