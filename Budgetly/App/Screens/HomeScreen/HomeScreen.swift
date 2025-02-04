import SwiftUI
import Charts
import Observation
import SwiftData

enum TimePeriod: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    case year = "Год"
    case allTime = "Все время"

    var id: String { rawValue }
}

struct HomeScreen: View {
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .allTime

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
            switch TimePeriod(rawValue: selectedTimePeriod.rawValue) ?? .allTime {
            case .day:
                return calendar.isDateInToday(transaction.date)
            case .week:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
    }

    var body: some View {

            NavigationStack {
                VStack {
                    accountView

                    transactionTypeControl

                    timePeriodPicker

                    PieChartView(transactions: filteredTransactions) // Перемещен ниже

                    List(filteredTransactions) { transaction in
                        HStack {
                            Text(transaction.category)
                            Spacer()
                            Text("\(transaction.amount, specifier: "%.2f") ₽")
                                .foregroundColor(transaction.type == .expenses ? .red : .green)
                        }
                    }
                    .listStyle(.plain)
                }
                .padding()
//                .navigationTitle("Бюджет")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) { // Центрируем заголовок и делаем белым
                        Text("Бюджет")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white) // Делаем текст белым
                    }
                }
                .background(GradientView()) // Градиентный фон
                .scrollContentBackground(.hidden) // Убираем фон
            }
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }
            .sheet(isPresented: $isAddTransactionViewPresented) {
                AddTransactionView(account: selectedAccount)
            }
    }

    private var accountView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Счет")
                    .font(.headline)

                Spacer()

                Picker("Выберите счет", selection: $selectedAccount) {
                    Text("Выберите счет")
                        .tag(nil as Account?)
                    ForEach(accounts) { account in
                        Text(account.name).tag(account as Account?)
                    }
                }
                .tint(.white) // Изменяет цвет выделенного текста на белый
                .foregroundColor(.white) // Применяется ко всем текстам внутри Picker
            }
            .foregroundStyle(.white)

            Text("Баланс")
                .foregroundStyle(.white)

            Text("\(saldo, specifier: "%.2f") ₽")
                .foregroundColor(saldo >= 0 ? .green : .red)
                .font(.title)
                .fontWeight(.semibold)

            Button("Добавить операцию") {
                isAddTransactionViewPresented = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundStyle(.white)
            .cornerRadius(24)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.8))
        .cornerRadius(24)
    }

    private var transactionTypeControl: some View {
        Picker("", selection: $selectedTransactionType) {
            Text("Расходы").tag(TransactionType.expenses)
            Text("Доходы").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
    }

//    private var timePeriodPicker: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 5) {
//                ForEach(TimePeriod.allCases) { period in
//                    Button(action: { selectedTimePeriod = period }) {
//                        Text(period.rawValue)
//                            .font(.caption)
//                            .frame(width: 55, height: 5)
//                            .padding()
//                            .background(selectedTimePeriod == period ? Color.blue : Color.gray)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                }
//            }
//        }
//        .padding(.bottom) // Отступ перед графиком
//    }

    private var timePeriodPicker: some View {
        HStack {
            Text("Период")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Picker("Выберите период", selection: $selectedTimePeriod) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .tint(.white) // Изменяет цвет выделенного текста на белый
            .foregroundColor(.white) // Применяется ко всем текстам внутри Picker
            .onAppear {
                selectedTimePeriod = .allTime
            }
        }
    }
}
