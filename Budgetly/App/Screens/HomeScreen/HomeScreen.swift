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
    case custom = "Выбрать период" // Новый пункт

    var id: String { rawValue }
}

struct HomeScreen: View {
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]

    @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .day
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false

    @State private var isGoldBagViewPresented = false
    @State private var isStatsViewPresented = false

    @Environment(\.modelContext) private var modelContext

    private let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    /// Баланс за выбранный период (учитывает все доходы и расходы)
    private var saldo: Double {
        let income = allPeriodTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = allPeriodTransactions
            .filter { $0.type == .expenses }
            .reduce(0) { $0 + $1.amount }

        return income - expenses
    }
    /// Все транзакции выбранного счёта за выбранный период (без учёта типа)
    private var allPeriodTransactions: [Transaction] {
        guard let account = selectedAccount else { return [] }
        let now = Date()
        let calendar = Calendar.current

        return account.transactions.filter { transaction in
            switch selectedTimePeriod {
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
            case .custom:
                  // Проверяем, что дата транзакции лежит между customStartDate и customEndDate
                  return transaction.date >= customStartDate && transaction.date <= customEndDate
            }
        }
    }
    /// Транзакции, выбранные по периоду и типу (для списка и диаграммы)
    var filteredTransactions: [Transaction] {
        allPeriodTransactions.filter { $0.type == selectedTransactionType }
    }

    var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(spacing: 32) {
                        accountView
                        transactionTypeControl
                    }

                    timePeriodPicker

                    PieChartView(transactions: filteredTransactions)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(filteredTransactions) { transaction in
                                // Карточка
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.category)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .minimumScaleFactor(0.8)

                                    Text("\(transaction.amount, specifier: "%.0f") ₽")
                                        .foregroundColor(.primary)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Color.colorForCategoryName(transaction.category, type: transaction.type)
                                        .opacity(0.8)
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                // Пример swipeActions (iOS 15+),
                                // но в гриде он будет работать чуть менее очевидно:
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if let index = filteredTransactions.firstIndex(where: { $0.id == transaction.id }) {
                                            deleteTransaction(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Мой Бюджет")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
                .background(.backgroundLightGray)
            }
            .onAppear {
            //    seedDefaultCategoriesIfNeeded()

                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }
//            .sheet(isPresented: $isGoldBagViewPresented) {
//                GoldBagView()
//            }
            .sheet(isPresented: $isAddTransactionViewPresented) {
                AddTransactionView(account: selectedAccount)
            }
//            .sheet(isPresented: $isStatsViewPresented) {
//                StatsView()
//            }
    }

    private var accountView: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                    Text("Счет")
                        .font(.headline)
                }
                .foregroundStyle(.primary)
                .font(.headline)

                Spacer()

                Picker("Выберите счет", selection: $selectedAccount) {
                    Text("Выберите счет")
                        .tag(nil as Account?)
                    ForEach(accounts) { account in
                        Text(account.name).tag(account as Account?)
                    }
                }
                .tint(.royalBlue).opacity(0.85) // Изменяет цвет выделенного текста на белый
            }

            VStack (spacing: 8) {
                Text("Баланс")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                Text("\(saldo, specifier: "%.1f") ₽")
                    .foregroundColor(.primary)
                    .font(.title)
                    .fontWeight(.bold)
            }

            Button("Добавить операцию") {
                isAddTransactionViewPresented = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.appPurple)
            .foregroundStyle(.white)
            .font(.headline)
            .cornerRadius(24)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 3, y: 6)
    }

    private var transactionTypeControl: some View {
        Picker("", selection: $selectedTransactionType) {
            Text("Расходы").tag(TransactionType.expenses)
            Text("Доходы").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        .frame(width: 240)
    }

    private var timePeriodPicker: some View {
        HStack {
            Text("Период")
                .font(.title3).bold()
                .foregroundStyle(.primary)

            Spacer()

            Picker("Выберите период", selection: $selectedTimePeriod) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .tint(.royalBlue).opacity(0.85)
            .onChange(of: selectedTimePeriod) { _, newValue in
                if newValue == .custom {
                    isCustomPeriodPickerPresented = true
                }
            }

            .onAppear {
                selectedTimePeriod = .day
            }
        }
        // При желании — sheet или .fullScreenCover
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: $customStartDate,
                endDate: $customEndDate
            )
        }
    }

    // Удаление транзакции
    private func deleteTransaction(at offsets: IndexSet) {
        // Индексы соответствуют позициям в filteredTransactions
        for index in offsets {
            let transactionToDelete = filteredTransactions[index]
            // Удаляем из SwiftData (modelContext)
            modelContext.delete(transactionToDelete)
        }
        // Сохраняем изменения
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении транзакции: \(error.localizedDescription)")
        }
    }
}

//экран, где пользователь выберет даты
struct CustomPeriodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Начало периода")) {
                    DatePicker("С", selection: $startDate, displayedComponents: .date)
                }
                Section(header: Text("Конец периода")) {
                    DatePicker("По", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Выберите период")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        // Закрываем sheet
                        dismiss()
                    }
                }
            }
        }
    }
}
