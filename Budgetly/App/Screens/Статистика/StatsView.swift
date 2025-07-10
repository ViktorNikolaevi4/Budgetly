
import SwiftUI
import SwiftData

enum StatsSegment: String, CaseIterable, Identifiable {
    case income = "Доходы"
    case expenses = "Расходы"
    case assets = "Активы"

    var id: String { rawValue }
}

struct StatsView: View {
    @Query private var accounts: [Account]
    // Массив всех транзакций
    @Query private var transactions: [Transaction]
    // Массив всех активов
    @Query private var assets: [Asset]

    // Состояние выбора сегмента: Доходы / Расходы / Активы
    @State private var selectedSegment: StatsSegment = .income
    @State private var selectedAccount: Account?

    // Состояние выбора периода
    @State private var selectedTimePeriod: TimePeriod = .allTime
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodPopover = false
    @State private var isShowingDateSheet = false


    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Внутри вашего VStack в StatsView вместо голого Picker:
                HStack(spacing: 12) {
                    // 1) Иконка и лейбл «Счет»
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Счет")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // 2) Сами выбор из списка счетов
                    Menu {
                        // Пункт «Все счета»
                        Button("Все счета") { selectedAccount = nil }
                        Divider()
                        // Остальные счета
                        ForEach(accounts) { account in
                            Button(account.name) {
                                selectedAccount = account
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedAccount?.name ?? "Все счета")
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }

                } // HStack
                .frame(width: 361, height: 54)
                .padding(.horizontal, 12)           // чтобы содержимое не впритык к краям
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 79/255, green: 184/255, blue: 255/255),
                            Color(red: 32/255, green: 60/255, blue: 255/255)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Сегментированный контрол для выбора: Доходы / Расходы / Активы
                segmentControl

                // Пикер периода (День, Неделя и т.д.)
                periodPicker

                // Список элементов внизу
                listOfFilteredItems
            }
            .padding()
            .navigationTitle("Статистика")
        }
        .onAppear {
            // По умолчанию первый счет
            if selectedAccount == nil {
                selectedAccount = accounts.first
            }
        }
        // Если выбрали "Выбрать период", показываем выбор дат
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: customStartDate,
                endDate: customEndDate,
                onApply: { start, end in
                    customStartDate = start
                    customEndDate = end }
            )
        }
    }

    // MARK: - Активы, отсортированные по цене ↓
    private var sortedAssets: [Asset] {
        assets.sorted {
            if $0.price != $1.price {
                return $0.price > $1.price      // сначала большая цена
            } else {
                return $0.name < $1.name        // потом алфавит
            }
        }
    }

    // MARK: - Сегментированный контрол (Доходы / Расходы / Активы)
    private var segmentControl: some View {
        Picker("", selection: $selectedSegment) {
            ForEach(StatsSegment.allCases) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Пикер периода (Popover и выбор дат)
    private var periodPicker: some View {
        Group {
            if selectedSegment != .assets {
                HStack {
                    Text("Период:")
                        .font(.title3).bold()

                    Spacer()

                    Button {
                        isShowingPeriodPopover.toggle()
                    } label: {
                        HStack {
                            Text(selectedPeriodTitle)
                                .foregroundColor(.appPurple.opacity(0.85))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.appPurple.opacity(0.85))
                        }
                    }
                    .popover(isPresented: $isShowingPeriodPopover, arrowEdge: .top) {
                        VStack(spacing: 0) {
                            ForEach(TimePeriod.allCases.indices, id: \.self) { index in
                                let period = TimePeriod.allCases[index]
                                Button(action: {
                                    selectedTimePeriod = period
                                    isShowingPeriodPopover = false
                                    if period == .custom {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isCustomPeriodPickerPresented = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text(period.rawValue)
                                            .foregroundColor(.primary)
                                            .padding(.vertical, 8)
                                        Spacer()
                                        if period == selectedTimePeriod {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.appPurple)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                // Если это не последний элемент – добавить Divider (подчеркивание)
                                if index < TimePeriod.allCases.count - 1 {
                                    Divider()
                                        .foregroundColor(Color(.systemGray4))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(width: 250)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .presentationCompactAdaptation(.popover)
                    }

                }
                // Sheet для кастомного периода
                .sheet(isPresented: $isCustomPeriodPickerPresented) {
                    CustomPeriodPickerView(
                        startDate: customStartDate,
                        endDate: customEndDate
                    ) { start, end in
                        customStartDate = start
                        customEndDate = end
                        selectedTimePeriod = .custom
                    }
                    .presentationDetents([.medium])
                }
            } else {
                EmptyView()
            }
        }
    }



    // MARK: - Список элементов (транзакций или активов) в зависимости от выбора
    @ViewBuilder
    private var listOfFilteredItems: some View {
        switch selectedSegment {
        case .income:
            // Сгруппированные доходы
            List(groupedIncomeTransactions, id: \.category) { group in
                HStack {
                    Text(group.category)
                    Spacer()
                    Text("\(group.total, specifier: "%.2f") ₽")
                        .foregroundColor(.black)
                        .font(.body)
                }
            }
        case .expenses:
            // Сгруппированные расходы
            List(groupedExpenseTransactions, id: \.category) { group in
                HStack {
                    Text(group.category)
                    Spacer()
                    Text("\(group.total, specifier: "%.2f") ₽")
                        .foregroundColor(.black)
                        .font(.body)
                }
            }
            // Показываем список всех активов (без фильтра по датам)
        case .assets:
            List(sortedAssets) { asset in          // ←  вместо  List(assets)
                HStack {
                    VStack(alignment: .leading) {
                        Text(asset.name)
                            .font(.headline)
                        Text(asset.assetType?.name ?? "Без типа")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(String(format: "%.2f ₽", asset.price))
                        .foregroundColor(.black)
                }
            }
        }
    }

    // MARK: - Группировка транзакций по категориям и суммирование
    private func groupedTransactions(_ transactions: [Transaction]) -> [(category: String, total: Double)] {
        // Используем Dictionary(grouping:by:) для группировки
        let dict = Dictionary(grouping: transactions, by: { $0.category })

        // Превращаем словарь в массив структур (category, total)
        // total — это сумма amounts в рамках каждой категории
        return dict.map { (category, txs) in
            let total = txs.reduce(0) { $0 + $1.amount }
            return (category: category, total: total)
        }
        .sorted {
            if $0.total != $1.total {
                return $0.total > $1.total   // сначала по сумме (по убыванию)
            } else {
                return $0.category < $1.category // потом по алфавиту
            }
        }
    }

    // MARK: - Фильтр доходов по периоду
    private var filteredIncomeTransactions: [Transaction] {
        transactions
            .filter { $0.type == .income }
            .filter(isInSelectedPeriod)
            .filter(isInSelectedAccount)
    }

    // MARK: - Фильтр расходов по периоду
    private var filteredExpenseTransactions: [Transaction] {
        transactions
            .filter { $0.type == .expenses }
            .filter(isInSelectedPeriod)
            .filter(isInSelectedAccount)
    }

    // MARK: - Сгруппированные доходы и расходы
    private var groupedIncomeTransactions: [(category: String, total: Double)] {
        groupedTransactions(filteredIncomeTransactions)
    }

    private var groupedExpenseTransactions: [(category: String, total: Double)] {
        groupedTransactions(filteredExpenseTransactions)
    }

    private var selectedPeriodTitle: String {
        if selectedTimePeriod == .custom {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMM yyyy"
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        } else {
            return selectedTimePeriod.rawValue
        }
    }
    private func isInSelectedAccount(_ tx: Transaction) -> Bool {
        guard let acct = selectedAccount else { return true }
        // сравниваем опциональный UUID с не-опциональным, Swift умеет это сделать:
        return tx.account?.id == acct.id
    }

    // MARK: - Проверка, попадает ли дата транзакции в выбранный период
    private func isInSelectedPeriod(_ transaction: Transaction) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        switch selectedTimePeriod {
        case .today:
            return calendar.isDateInToday(transaction.date)
        case .currentWeek:
            return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
        case .currentMonth:
            return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        case .previousMonth:
            guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return false
            }
            guard let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else {
                return false
            }
            guard let startOfPreviousMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: endOfPreviousMonth)) else {
                return false
            }
            return transaction.date >= startOfPreviousMonth && transaction.date <= endOfPreviousMonth
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
            return transaction.date >= customStartDate && transaction.date <= customEndDate
        }
    }
}
