import SwiftUI
import Charts
import Observation
import SwiftData

enum TimePeriod: String, CaseIterable, Identifiable {
    case today = "Сегодня"
    case currentWeek = "Текущая неделя"
    case currentMonth = "Текущий месяц"
    case previousMonth = "Прошлый месяц"
    case last3Months = "Последние 3 месяца"
    case year = "Год"
    case allTime = "Все время"
    case custom = "Выбрать период"

    var id: String { rawValue }
}
/// Модель для хранения агрегированных данных по одной категории
struct AggregatedTransaction: Identifiable {
    let id = UUID()            // Для ForEach (уникальный идентификатор)
    let category: String       // Название категории
    let totalAmount: Double    // Сумма по категории
}

struct HomeScreen: View {
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]

    @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .today
 //   @State private var customStartDate: Date = Date()
 //   @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodMenu = false

    @State private var appliedStartDate: Date?
    @State private var appliedEndDate: Date?

    @State private var isGoldBagViewPresented = false
    @State private var isStatsViewPresented = false

    @Environment(\.modelContext) private var modelContext

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
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
            case .today:
                return calendar.isDateInToday(transaction.date)
            case .currentWeek:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case .currentMonth:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .previousMonth:
                guard let startOfCurrentMonth = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: now)
                ) else {
                    return false
                }
                guard let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else {
                    return false
                }
                guard let startOfPreviousMonth = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: endOfPreviousMonth)
                ) else {
                    return false
                }
                return (transaction.date >= startOfPreviousMonth && transaction.date <= endOfPreviousMonth)

            case .last3Months:
                guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else {
                    return false
                }
                return transaction.date >= threeMonthsAgo && transaction.date <= now
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            case .custom:
                guard let startDate = appliedStartDate, let endDate = appliedEndDate else {
                    return false
                }
                return (transaction.date >= startDate && transaction.date <= endDate)
            }
        }
    }

    /// Транзакции, выбранные по периоду и типу (для списка и диаграммы)
    var filteredTransactions: [Transaction] {
        allPeriodTransactions.filter { $0.type == selectedTransactionType }
    }

    private var aggregatedTransactions: [AggregatedTransaction] {
        // 1. Сгруппировать по названию категории (Dictionary<GroupKey, [Transaction]>)
        let groupedByCategory = Dictionary(grouping: filteredTransactions, by: { $0.category })

        // 2. Преобразовать каждую группу в AggregatedTransaction
        //    Ключ — категория, значение — массив транзакций
        return groupedByCategory.map { (category, transactions) in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return AggregatedTransaction(category: category, totalAmount: total)
        }
    }

    var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 32) {
                            accountView
                            transactionTypeControl
                        }
                        timePeriodPicker
                        PieChartView(transactions: filteredTransactions)
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(aggregatedTransactions) { agg in
                                // "agg" — это AggregatedTransaction
                                HStack(spacing: 8) {
                                    Text(agg.category)
                                        .font(.body)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Text("\(agg.totalAmount.toShortStringWithSuffix()) ₽")
                                        .foregroundColor(.primary)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                            //    .frame(maxWidth: .infinity)
                                .background(
                                    Color.colorForCategoryName(agg.category, type: selectedTransactionType)
                                        .opacity(0.8)
                                )
                                .cornerRadius(12)
                              //  .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                // Пример swipeActions (iOS 15+),
                                // но в гриде он будет работать чуть менее очевидно:
                                .contextMenu {
                                    // При нажатии "Удалить" удаляем только за период
                                    Button(role: .destructive) {
                                        deleteAllTransactionsInPeriod(for: agg.category)
                                    } label: {
                                        Label("Удалить (\(agg.category)) за период", systemImage: "trash")
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

    private var selectedPeriodTitle: String {
        if selectedTimePeriod == .custom,
           let startDate = appliedStartDate,
           let endDate = appliedEndDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMM yyyy"
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        } else {
            return selectedTimePeriod.rawValue
        }
    }

    private var accountView: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                    Text("Счет")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .font(.headline)

                Spacer()

                Picker("Выберите счет", selection: $selectedAccount) {
                    Text("Выберите счет")
                        .tag(nil as Account?)
                    ForEach(accounts) { account in
                        Text(account.name).tag(account as Account?)
                    }
                }
                .tint(.white).opacity(0.85) // Изменяет цвет выделенного текста на белый
            }

            VStack (spacing: 8) {
                Text("Баланс")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.subheadline)

                Text("\(saldo, specifier: "%.1f") ₽")
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
            }

            Button {
                isAddTransactionViewPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.ring.dashed")
                        .imageScale(.medium) // или .large
                    Text("Добавить операцию")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(.appPurple)
                .foregroundStyle(.white)
                .cornerRadius(16)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
LinearGradient(stops: [
    Gradient.Stop(color: Color(red: 79.0 / 255.0, green: 184.0 / 255.0, blue: 1.0), location: 0.0),
    Gradient.Stop(color: Color(red: 32.0 / 255.0, green: 60.0 / 255.0, blue: 1.0), location: 1.0)],
               startPoint: .topLeading,
               endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .padding(.horizontal, 6)
        .shadow(color: Color.black.opacity(0.2), radius: 3)
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

            Button {
                isShowingPeriodMenu.toggle()
            } label: {
                HStack {
                    Text(selectedPeriodTitle)
                        .foregroundColor(.appPurple.opacity(0.85))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.appPurple.opacity(0.85))
                }
            }
            .popover(isPresented: $isShowingPeriodMenu, arrowEdge: .top) {
                VStack(spacing: 0) {
                    ForEach(TimePeriod.allCases.indices, id: \.self) { index in
                        let period = TimePeriod.allCases[index]

                        Button {
                            // Закрываем popover
                            isShowingPeriodMenu = false
                            // Меняем выбранный период
                            selectedTimePeriod = period
                            // Если пользователь выбрал "Выбрать период"
                            if period == .custom {
                                // С небольшой задержкой открываем sheet
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isCustomPeriodPickerPresented = true
                                }
                            }
                        } label: {
                            HStack {
                                Text(period.rawValue)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 8)
                                Spacer()
                                // Если этот период сейчас выбран, показываем галочку
                                if period == selectedTimePeriod {
                                    Image(systemName: "checkmark")
                                        // Цвет можно сделать единым, например .appPurple
                                        .foregroundColor(.appPurple)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Добавляем Divider, если это не последний элемент
                        if index < TimePeriod.allCases.count - 1 {
                            Divider()
                                .foregroundStyle(Color(.systemGray4))
                        }
                    }
                }
                .padding(.vertical, 8)               // Внешний вертикальный отступ для списка
                .frame(width: 250)                   // Фиксированная ширина popover
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(radius: 5)
                .presentationCompactAdaptation(.popover)
            }

        }
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: appliedStartDate ?? Date(),
                endDate: appliedEndDate ?? Date()
            ) { start, end in
                appliedStartDate = start
                appliedEndDate = end
            }
            .presentationDetents([.medium])
        }
    }
    // Удаление транзакции
    private func deleteAllTransactionsInPeriod(for categoryName: String) {
        // Собираем все "сырые" транзакции, которые видны (т.е. прошли фильтр)
        // и у которых нужная категория
        let toDelete = filteredTransactions.filter { $0.category == categoryName }

        // Удаляем каждую
        for transaction in toDelete {
            modelContext.delete(transaction)
        }
        // Сохраняем
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении транзакций: \(error.localizedDescription)")
        }
    }


}

//экран, где пользователь выберет даты
struct CustomPeriodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date

    var onApply: (Date, Date) -> Void

    init(startDate: Date, endDate: Date, onApply: @escaping (Date, Date) -> Void) {
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Text("Выберите период")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                VStack(spacing: 16) {
                    DatePicker("Дата начала", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .tint(.appPurple)

                    DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .tint(.appPurple)
                }
                // Кнопка "Применить"
                Button(action: {
                    onApply(startDate, endDate)
                    dismiss() // Закрываем и применяем фильтр
                }) {
                    Text("Применить")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.appPurple)
                        .foregroundStyle(.white)
                        .font(.headline)
                        .cornerRadius(24)
                        .padding()
                }
                .padding(.bottom, 24)
            }
            Spacer()
        }
        .environment(\.locale, Locale(identifier: "ru_RU"))
    }

}

extension Double {
    /// Возвращает строку с сокращением (1,2 тыс., 5,5 млн, 1,0 млрд, etc.)
    /// с учётом российских обозначений.
    func toShortStringWithSuffix() -> String {
        let absValue = abs(self)

        // Можно проверять диапазоны:
        switch absValue {
        case 1_000_000_000...: // от 1 млрд
            let shortened = self / 1_000_000_000
            return String(format: "%.1f млрд", shortened)
        case 1_000_000...: // от 1 млн
            let shortened = self / 1_000_000
            return String(format: "%.1f млн", shortened)
//        case 1_000...: // от 1 тыс.
//            let shortened = self / 1_000
//            return String(format: "%.1f тыс.", shortened)
        default:
            // Если число меньше 1000, показываем целое или с десятыми (на ваш вкус)
            return String(format: "%.0f", self)
        }
    }
}
