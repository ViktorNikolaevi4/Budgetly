
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
    @Query private var transactions: [Transaction]
    @Query private var assets: [Asset]
    @Query private var allCategories: [Category]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSegment: StatsSegment = .income
    @State private var selectedAccount: Account?
    @State private var selectedTimePeriod: TimePeriod = .allTime
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodPopover = false
    @State private var isShowingDeleteAlert = false
    @State private var pendingDeleteTransaction: Transaction?
    @State private var expandedCategories: Set<String> = []
    @State private var expandedItems: Set<String> = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.title3)
                                .foregroundColor(.white)
                            Text("Счет")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Menu {
                            Button("Все счета") { selectedAccount = nil }
                            Divider()
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
                    }
                    .frame(height: 54)
                    .padding(.horizontal, 16)
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

                    segmentControl
                    periodPicker
                    listOfFilteredItems
                }
                .padding()
                .navigationTitle("Статистика")
                .navigationBarTitleDisplayMode(.large)
            }
            .alert(
                "Подтвердить удаление",
                isPresented: $isShowingDeleteAlert
            ) {
                Button("Удалить", role: .destructive) {
                    if let transaction = pendingDeleteTransaction {
                        delete(transaction: transaction)
                    }
                }
                Button("Отмена", role: .cancel) {
                    pendingDeleteTransaction = nil
                }
            } message: {
                Text("Вы уверены, что хотите удалить эту транзакцию?")
            }
        }
        .onAppear {
            if selectedAccount == nil {
                selectedAccount = accounts.first
            }
        }
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: customStartDate,
                endDate: customEndDate,
                onApply: { start, end in
                    customStartDate = start
                    customEndDate = end
                    selectedTimePeriod = .custom
                }
            )
            .presentationDetents([.medium])
        }
    }

    private var sortedAssets: [Asset] {
        assets.sorted {
            if $0.price != $1.price {
                return $0.price > $1.price
            } else {
                return $0.name < $1.name
            }
        }
    }

    private var totalAssets: Double {
        assets.reduce(0) { $0 + $1.price }
    }

    private var groupedAssetsByType: [(type: String, total: Double)] {
        Dictionary(grouping: assets, by: { $0.assetType?.name ?? "Без типа" })
            .map { (type, items) in
                (type: type, total: items.reduce(0) { $0 + $1.price })
            }
            .sorted {
                if $0.total != $1.total {
                    return $0.total > $1.total
                } else {
                    return $0.type < $1.type // Алфавитный порядок при равных суммах
                }
            }
    }

    private var segmentControl: some View {
        Picker("", selection: $selectedSegment) {
            ForEach(StatsSegment.allCases) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

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
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var listOfFilteredItems: some View {
        List {
            switch selectedSegment {
            case .income, .expenses:
                // 1) Доходы / Расходы
                let allTx = (selectedSegment == .income)
                    ? filteredIncomeTransactions
                    : filteredExpenseTransactions
                let total = allTx.reduce(0) { $0 + $1.amount }
                let groups = groupedTransactions(allTx)

                ForEach(groups, id: \.category) { group in
                    // считаем общий total для этого сегмента
                    let total = allTx.reduce(0) { $0 + $1.amount }
                    let percent = group.total / (total == 0 ? 1 : total) * 100

                    // — вместо HStack просто оборачиваем всё в VStack
                    VStack(alignment: .leading, spacing: 8) {
                        // 1) Заголовок: иконка, название, сумма, стрелка
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        Color.colorForCategoryName(
                                            group.category,
                                            type: selectedSegment == .income ? .income : .expenses
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                                Image(
                                    systemName:
                                        categoryObject(named: group.category)?
                                        .iconName
                                    ?? defaultIconName(for: group.category)
                                )
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            }
                            Text(group.category)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(group.total, specifier: "%.2f") ₽")
                                .font(.body)
                                .foregroundColor(.primary)
                            Image(systemName:
                                    expandedItems.contains(group.category)
                                    ? "chevron.up"
                                    : "chevron.down"
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        // 2) Прогресс-бар
                        ProgressView(value: group.total, total: total)
                            .tint(
                                Color.colorForCategoryName(
                                    group.category,
                                    type: selectedSegment == .income ? .income : .expenses
                                )
                            )
                            .frame(height: 4)
                            .padding(.horizontal, 48)

                        // 3) Процент под полосой
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f%%", percent))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            if expandedItems.contains(group.category) {
                                expandedItems.remove(group.category)
                            } else {
                                expandedItems.insert(group.category)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // Детали транзакций
                    if expandedItems.contains(group.category) {
                        let txs = transactions(for: group.category, in: allTx)
                        ForEach(txs, id: \.id) { tx in
                            HStack {
                                Text(dayFormatter.string(from: tx.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(tx.amount, specifier: "%.2f") ₽")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.visible)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    // 1) Сохраняем tx и показываем алерт
                                    pendingDeleteTransaction = tx
                                    isShowingDeleteAlert = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }

                }

            case .assets:
                // Общая стоимость
                HStack {
                    Text("Общая стоимость активов:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(totalAssets, specifier: "%.2f") ₽")
                        .font(.subheadline).bold()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Сам список типов активов
                ForEach(groupedAssetsByType, id: \.type) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(group.type)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(group.total, specifier: "%.2f") ₽")
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        ProgressView(value: group.total, total: totalAssets)
                            .tint(.appPurple)
                            .frame(height: 4)

                        HStack {
                            Spacer()
                            Text(
                                String(
                                    format: "%.1f%%",
                                    group.total / (totalAssets == 0 ? 1 : totalAssets) * 100
                                )
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
    }


    private func delete(transaction: Transaction) {
        modelContext.delete(transaction)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении транзакции: \(error.localizedDescription)")
        }
        pendingDeleteTransaction = nil
    }

    private func categoryObject(named name: String) -> Category? {
        guard let acct = selectedAccount else { return nil }
        return allCategories.first {
            $0.account?.id == acct.id && $0.name == name
        }
    }

    private func defaultIconName(for categoryName: String) -> String {
        switch categoryName {
        case Category.uncategorizedName: return "circle.slash"
        case "Еда": return "fork.knife"
        case "Транспорт": return "car.fill"
        case "Дом": return "house.fill"
        case "Одежда": return "tshirt.fill"
        case "Здоровье": return "bandage.fill"
        case "Питомцы": return "pawprint.fill"
        case "Связь": return "wifi"
        case "Развлечения": return "gamecontroller.fill"
        case "Образование": return "book.fill"
        case "Дети": return "figure.walk"
        case "Зарплата": return "wallet.bifold.fill"
        case "Дивиденды": return "chart.line.uptrend.xyaxis"
        case "Купоны": return "banknote"
        case "Продажи": return "dollarsign.circle.fill"
        case "Премия": return "star.circle.fill"
        case "Вклады": return "dollarsign.bank.building.fill"
        case "Аренда": return "house.fill"
        case "Подарки": return "gift.fill"
        case "Подработка": return "hammer.fill"
        default: return "circle.slash.fill"
        }
    }
    private func transactions(for category: String, in txs: [Transaction]) -> [Transaction] {
        txs
          .filter { $0.category == category }
          .sorted { $0.date > $1.date }
    }
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMM yyyy"
        return df
    }()

    private func dailyTotals(for category: String, in transactions: [Transaction]) -> [(date: Date, total: Double)] {
        let filtered = transactions.filter { $0.category == category }
        let dict = Dictionary(grouping: filtered) { tx -> Date in
            Calendar.current.startOfDay(for: tx.date)
        }
        return dict.map { (day, txs) in
            (date: day, total: txs.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.date > $1.date }
    }

    private func groupedTransactions(_ transactions: [Transaction]) -> [(category: String, total: Double)] {
        let dict = Dictionary(grouping: transactions, by: { $0.category })
        return dict.map { (category, txs) in
            let total = txs.reduce(0) { $0 + $1.amount }
            return (category: category, total: total)
        }
        .sorted {
            if $0.total != $1.total {
                return $0.total > $1.total
            } else {
                return $0.category < $1.category
            }
        }
    }

    private var filteredIncomeTransactions: [Transaction] {
        transactions
            .filter { $0.type == .income }
            .filter(isInSelectedPeriod)
            .filter(isInSelectedAccount)
    }

    private var filteredExpenseTransactions: [Transaction] {
        transactions
            .filter { $0.type == .expenses }
            .filter(isInSelectedPeriod)
            .filter(isInSelectedAccount)
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
        return tx.account?.id == acct.id
    }

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
