import SwiftUI
import SwiftData

enum StatsSegment: String, CaseIterable, Identifiable {
    case income = "Доходы"
    case expenses = "Расходы"
    case assets = "Активы"
    var id: String { rawValue }
}

struct StatsView: View {
    // MARK: — Queries & Environment
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @Query private var assets: [Asset]
    @Query private var allCategories: [Category]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: — State
    @State private var selectedSegment: StatsSegment = .income
    @State private var selectedAccount: Account?
    @State private var selectedTimePeriod: TimePeriod = .allTime
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodPopover = false
    @State private var isShowingDeleteAlert = false
    @State private var pendingDeleteTransaction: Transaction?
    @State private var expandedItems: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 16) {
                    headerView
                    segmentControl
                    periodPicker

                    if selectedSegment != .assets {
                        (
                            Text("За \(selectedPeriodTitle) вы ")
                            + Text(selectedSegment == .income ? "получили " : "потратили ")
                            + Text(sumForPeriod.money(.short, symbol: currencySign)).bold().foregroundStyle(.primary)
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    }

                    listOfFilteredItems
                }
                .padding()
                .navigationTitle("Статистика")
                .navigationBarTitleDisplayMode(.large)
                .alert("Подтвердить удаление",
                       isPresented: $isShowingDeleteAlert
                ) {
                    Button("Удалить", role: .destructive) {
                        if let tx = pendingDeleteTransaction {
                            delete(tx)
                        }
                    }
                    Button("Отмена", role: .cancel) {
                        pendingDeleteTransaction = nil
                    }
                } message: {
                    Text("Вы уверены, что хотите удалить эту транзакцию?")
                }
            }
        }
        .onAppear {
            if selectedAccount == nil {
                selectedAccount = accounts.first
            }
        }
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(startDate: customStartDate,
                                   endDate: customEndDate) { start, end in
                customStartDate = start
                customEndDate = end
                selectedTimePeriod = .custom
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: — Header
    private var headerView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.title3).foregroundColor(.white)
                Text("Счет")
                    .font(.headline).foregroundColor(.white)
            }
            Spacer()
            Menu {
                Button("Все счета") { selectedAccount = nil }
                Divider()
                ForEach(accounts) { acct in
                    Button(acct.name) { selectedAccount = acct }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedAccount?.name ?? "Все счета")
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.caption).foregroundColor(.white)
                }
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 184/255, blue: 255/255),
                    Color(red: 32/255, green: 60/255, blue: 255/255)
                ], startPoint: .leading, endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: — Segment Control
    private var segmentControl: some View {
        Picker("", selection: $selectedSegment) {
            ForEach(StatsSegment.allCases) { seg in
                Text(seg.rawValue).tag(seg)
            }
        }
        .pickerStyle(.segmented)
    }

    private var currencySign: String {
        guard let code = selectedAccount?.currency else { return "₽" }
        return currencySymbols[code] ?? code
    }

    // MARK: — Period Picker
    private var periodPicker: some View {
        Group {
            if selectedSegment != .assets {
                HStack {
                    Text("Период:").font(.title3).bold()
                    Spacer()
                    Button { isShowingPeriodPopover.toggle() } label: {
                        HStack {
                            Text(selectedPeriodTitle)
                                .foregroundColor(.appPurple.opacity(0.85))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.appPurple.opacity(0.85))
                        }
                    }
                    .popover(isPresented: $isShowingPeriodPopover, arrowEdge: .top) {
                        periodList
                    }
                }
            }
        }
    }

    private var periodList: some View {
        VStack(spacing: 0) {
            ForEach(TimePeriod.allCases.indices, id: \.self) { idx in
                let period = TimePeriod.allCases[idx]
                Button {
                    selectedTimePeriod = period
                    isShowingPeriodPopover = false
                    if period == .custom {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isCustomPeriodPickerPresented = true
                        }
                    }
                } label: {
                    HStack {
                        Text(period.rawValue).foregroundColor(.primary)
                            .padding(.vertical, 8)
                        Spacer()
                        if period == selectedTimePeriod {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appPurple)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                if idx < TimePeriod.allCases.count - 1 {
                    Divider().foregroundColor(Color(.systemGray4))
                }
            }
        }
        .padding(.vertical, 8)
        .frame(width: 250)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12).shadow(radius: 5)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: — Main List
    @ViewBuilder
    private var listOfFilteredItems: some View {
        List {
            switch selectedSegment {
            case .income:
                let txs = filteredIncomeTransactions
                if txs.isEmpty {
                    emptyStateView(
                        imageName: "РукаСмешком",
                        title: "Здесь пока пусто",
                        message: "Вы ещё не добавили ни одной операции.\nПопробуйте выбрать другой счёт или период — или начните с первой записи 💰"
                    )
                } else {
                    incomeExpenseList(txs, isIncome: true)
                }

            case .expenses:
                let txs = filteredExpenseTransactions
                if txs.isEmpty {
                    emptyStateView(
                        imageName: "Портманэ",
                        title: "Здесь пока пусто",
                        message: "Вы ещё не добавили ни одной траты.\nПопробуйте выбрать другой счёт или период — или начните с первой записи 💸"
                    )
                } else {
                    incomeExpenseList(txs, isIncome: false)
                }

            case .assets:
                let groups = groupedAssetsByType
                if groups.isEmpty {
                    emptyStateView(
                        imageName: "ДеревоСмонетой",
                        title: "Пока у вас нет активов",
                        message: "Выберите другой счёт или добавьте первую запись, чтобы начать строить свой портфель 💎"
                    )
                } else {
                    // Общая стоимость
                    HStack {
                        Text("Общая стоимость активов:")
                            .font(.subheadline).foregroundColor(.gray)
                        Spacer()
                        Text(totalAssets.money(.short, symbol: currencySign))
                            .font(.subheadline).bold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    ForEach(Array(groupedAssetsByType.enumerated()), id: \.element.type) { idx, group in
                        // Подбираем цвет по порядку (и оборачиваем по кругу, если групп больше, чем цветов)
                        let color = Color.predefinedColors[idx % Color.predefinedColors.count]
                        assetRow(group, tintColor: color)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
    }

    // MARK: — Empty State View
    @ViewBuilder
    private func emptyStateView(
        imageName: String, title: String, message: String
    ) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 32)
            Image(imageName)
                .resizable().scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary.opacity(0.6))
            Text(title).font(.headline).foregroundColor(.primary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: — Income/Expense Rows
    @ViewBuilder
    private func incomeExpenseList(_ txs: [Transaction], isIncome: Bool) -> some View {
        let total = txs.reduce(0) { $0 + $1.amount }
        let groups = groupedTransactions(txs)
        ForEach(groups, id: \.category) { group in
            let percent = group.total / (total == 0 ? 1 : total) * 100
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.colorForCategoryName(
                                group.category,
                                type: isIncome ? .income : .expenses
                            ))
                            .frame(width: 28, height: 28)
                        Image(systemName:
                            categoryObject(named: group.category)?
                            .iconName ?? defaultIconName(for: group.category)
                        )
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    }
                    Text(group.category).font(.body).foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 0) {
                        Text(group.total.money(.short, symbol: currencySign))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.leading, 4) // вот отступ перед знаком
                    }
                    Image(systemName:
                        expandedItems.contains(group.category)
                        ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                }

                ProgressView(value: group.total, total: total)
                    .tint(Color.colorForCategoryName(
                        group.category,
                        type: isIncome ? .income : .expenses
                    ))
                    .frame(height: 4)
                    .padding(.horizontal, 48)

                HStack {
                    Spacer()
                    Text(String(format: "%.1f%%", percent))
                        .font(.caption).foregroundColor(.gray)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { toggle(group.category) }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if expandedItems.contains(group.category) {
                let details = transactions(for: group.category, in: txs)
                ForEach(details, id: \.id) { tx in
                    HStack {
                        Text(dayFormatter.string(from: tx.date))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 0) {
                            Text(tx.amount.money(.short, symbol: currencySign))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.visible)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeleteTransaction = tx
                            isShowingDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: — Assets Row
    @ViewBuilder
    private func assetRow(
        _ group: (type: String, total: Double),
        tintColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.type)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 0) {
                    Text(group.total.money(.short, symbol: currencySign))
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            // Вот здесь используем переданный цвет
            ProgressView(value: group.total, total: totalAssets)
                .tint(tintColor)
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



    // MARK: — Helpers
    private func delete(_ tx: Transaction) {
        modelContext.delete(tx)
        try? modelContext.save()
        pendingDeleteTransaction = nil
    }

    private func toggle(_ key: String) {
        if expandedItems.contains(key) {
            expandedItems.remove(key)
        } else {
            expandedItems.insert(key)
        }
    }

    private func categoryObject(named name: String) -> Category? {
        guard let a = selectedAccount else { return nil }
        return allCategories.first {
            $0.account?.id == a.id && $0.name == name
        }
    }

    private func defaultIconName(for c: String) -> String {
        switch c {
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
        txs.filter { $0.category == category }
           .sorted { $0.date > $1.date }
    }

    private func groupedTransactions(_ txs: [Transaction]) -> [(category: String, total: Double)] {
        Dictionary(grouping: txs, by: { $0.category })
            .map { (k, v) in (category: k, total: v.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total != $1.total
                      ? $0.total > $1.total
                      : $0.category < $1.category }
    }

    private var filteredIncomeTransactions: [Transaction] {
        transactions.filter { $0.type == .income }
                    .filter(isInSelectedPeriod)
                    .filter(isInSelectedAccount)
    }
    private var filteredExpenseTransactions: [Transaction] {
        transactions.filter { $0.type == .expenses }
                    .filter(isInSelectedPeriod)
                    .filter(isInSelectedAccount)
    }

    private var totalAssets: Double {
        assets.reduce(0) { $0 + $1.price }
    }
    private var groupedAssetsByType: [(type: String, total: Double)] {
        // 1. Сгруппировали по имени типа
        let dict = Dictionary(grouping: assets) { asset in
            asset.assetType?.name ?? "Без типа"
        }

        // 2. Поскладывали цены в каждом подмассиве
        let mapped: [(type: String, total: Double)] = dict.map { (type, items) in
            let sum = items.reduce(0) { $0 + $1.price }
            return (type: type, total: sum)
        }

        // 3. Отсортировали результат
        let sorted = mapped.sorted { lhs, rhs in
            if lhs.total != rhs.total {
                return lhs.total > rhs.total
            } else {
                return lhs.type < rhs.type
            }
        }

        return sorted
    }


    private var selectedPeriodTitle: String {
        if selectedTimePeriod == .custom {
            let df = DateFormatter()
            df.locale = Locale(identifier: "ru_RU")
            df.dateFormat = "d MMM yyyy"
            return "\(df.string(from: customStartDate)) – \(df.string(from: customEndDate))"
        } else {
            return selectedTimePeriod.rawValue
        }
    }

    private var sumForPeriod: Double {
        switch selectedSegment {
        case .income:  return filteredIncomeTransactions.reduce(0) { $0 + $1.amount }
        case .expenses: return filteredExpenseTransactions.reduce(0) { $0 + $1.amount }
        default: return 0
        }
    }

    private func isInSelectedAccount(_ tx: Transaction) -> Bool {
        guard let a = selectedAccount else { return true }
        return tx.account?.id == a.id
    }
    private func isInSelectedPeriod(_ tx: Transaction) -> Bool {
        let now = Date(), cal = Calendar.current
        switch selectedTimePeriod {
        case .today: return cal.isDateInToday(tx.date)
        case .currentWeek:
            return cal.isDate(tx.date, equalTo: now, toGranularity: .weekOfYear)
        case .currentMonth:
            return cal.isDate(tx.date, equalTo: now, toGranularity: .month)
        case .previousMonth:
            guard let start = cal.date(from: cal.dateComponents([.year, .month], from: now)),
                  let endPrev = cal.date(byAdding: .day, value: -1, to: start),
                  let startPrev = cal.date(from: cal.dateComponents([.year, .month], from: endPrev))
            else { return false }
            return tx.date >= startPrev && tx.date <= endPrev
        case .last3Months:
            guard let ago = cal.date(byAdding: .month, value: -3, to: now)
            else { return false }
            return tx.date >= ago && tx.date <= now
        case .year:
            return cal.isDate(tx.date, equalTo: now, toGranularity: .year)
        case .allTime:
            return true
        case .custom:
            return tx.date >= customStartDate && tx.date <= customEndDate
        }
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM yyyy"
        return f
    }()
}
