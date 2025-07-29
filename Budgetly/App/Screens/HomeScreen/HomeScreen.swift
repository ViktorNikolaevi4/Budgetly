import SwiftUI
import Charts
import Observation
import SwiftData
import Foundation

let currencySymbols: [String: String] = [
    "RUB": "₽",
    "USD": "$",
    "EUR": "€",
    "GBP": "£",
    "JPY": "¥",
    "CNY": "¥"
]

/// Частота повторения транзакции
enum ReminderFrequenci: String, CaseIterable, Identifiable {
    case never          = "Никогда"
    case daily          = "Каждый день"
    case weekly         = "Каждую неделю"
    case biweekly       = "Каждые 2 недели"
    case monthly        = "Каждый месяц"
    case bimonthly      = "Каждые 2 месяца"
    case trimonthly     = "Каждые 3 месяца"
    case semiannually   = "Каждые 6 месяцев"
    case yearly         = "Каждый год"

    var id: String { rawValue }

    /// Удобный калькулятор сдвига даты для создания следующей транзакции
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
            switch self {
            case .never:
                // больше никаких повторений
                return date

            case .daily:
                return calendar.date(byAdding: .day, value: 1, to: date) ?? date

            case .weekly:
                return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date

            case .biweekly:
                return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date

            case .monthly:
                return calendar.date(byAdding: .month, value: 1, to: date) ?? date

            case .bimonthly:
                return calendar.date(byAdding: .month, value: 2, to: date) ?? date

            case .trimonthly:
                return calendar.date(byAdding: .month, value: 3, to: date) ?? date

            case .semiannually:
                return calendar.date(byAdding: .month, value: 6, to: date) ?? date

            case .yearly:
                return calendar.date(byAdding: .year, value: 1, to: date) ?? date
            }
        }
    }


enum TimePeriod: String, CaseIterable, Identifiable {
    case today = "Сегодня"
    case currentWeek = "Эта неделя"
    case currentMonth = "Этот месяц"
    case previousMonth = "Прошлый месяц"
    case last3Months = "Последние 3 месяца"
    case year = "Этот Год"
    case allTime = "За все время"
    case custom = "Свой период"

    var id: String { rawValue }
}
/// Модель для хранения агрегированных данных по одной категории
struct AggregatedTransaction: Identifiable {
    let id = UUID()            // Для ForEach (уникальный идентификатор)
    let category: String       // Название категории
    let totalAmount: Double    // Сумма по категории
}

/// Простой потоковый (wrap)‑лейаут
struct FlowLayout: Layout {

    var spacing: CGFloat = 4          // отступы между элементами

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {

        // Максимальная ширина, которую нам разрешили
        let maxWidth = proposal.width ?? .infinity

        var rowWidth:  CGFloat = 0     // ширина текущей строки
        var rowHeight: CGFloat = 0     // высота текущей строки
        var totalHeight: CGFloat = 0   // суммарная высота

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            // Перепрыгиваем на новую строку?
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth  = 0
                rowHeight = 0
            }
            rowWidth  += size.width + spacing
            rowHeight  = max(rowHeight, size.height)
        }
        // прибавляем последнюю строку
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {

        let maxX = bounds.maxX
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x + size.width > maxX {          // перенос
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            view.place(at: CGPoint(x: x, y: y),
                       proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct HomeScreen: View {
    @AppStorage("selectedAccountID") private var selectedAccountID: String = ""
    @Query private var accounts: [Account]
    @Query private var regularPayments: [RegularPayment]
    @Query private var allCategories: [Category]

  //  @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .currentMonth
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodMenu = false

    @State private var appliedStartDate: Date?
    @State private var appliedEndDate: Date?

    @Environment(\.modelContext) private var modelContext

    private var selectedAccount: Account? {
        accounts.first { $0.id.uuidString == selectedAccountID } ?? accounts.first
    }

    /// Баланс за выбранный период (учитывает все доходы и расходы)
    /// Баланс за выбранный период (учитывает начальный баланс + доходы − расходы)
    private var saldo: Double {
        guard let account = selectedAccount else { return 0 }
        // 1) Начальный баланс (или 0, если не задан)
        let base = account.initialBalance ?? 0
        // 2) Сумма доходов за период
        let income = allPeriodTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        // 3) Сумма расходов за период
        let expenses = allPeriodTransactions
            .filter { $0.type == .expenses }
            .reduce(0) { $0 + $1.amount }
        // 4) Итого: initialBalance + доходы − расходы
        return base + income - expenses
    }

    /// Все транзакции выбранного счёта за выбранный период (без учёта типа)
    private var allPeriodTransactions: [Transaction] {
        guard let account = selectedAccount else { return [] }

        guard let (start, end) = periodRange(for: selectedTimePeriod) else {
            return account.allTransactions
        }

        return account.allTransactions.filter { tx in
            (tx.date >= start) && (tx.date <= end)
        }
    }

    private func periodRange(for period: TimePeriod,
                             now: Date = .init(),
                             calendar: Calendar = .current) -> (Date, Date)? {
        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)

        case .currentWeek:
            guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
            return (start, now)

        case .currentMonth:
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return nil }
            return (start, now)

        case .previousMonth:
            guard
                let startOfCurMonth = calendar.dateInterval(of: .month, for: now)?.start,
                let endPrev = calendar.date(byAdding: .day, value: -1, to: startOfCurMonth),
                let startPrev = calendar.dateInterval(of: .month, for: endPrev)?.start
            else { return nil }
            return (startPrev, endPrev)

        case .last3Months:
            guard let start = calendar.date(byAdding: .month, value: -3, to: now) else { return nil }
            return (start, now)

        case .year:
            guard let start = calendar.dateInterval(of: .year, for: now)?.start else { return nil }
            return (start, now)

        case .custom:
            if let s = appliedStartDate, let e = appliedEndDate { return (s, e) }
            return nil                 // не выбрали — падаем на default

        case .allTime:
            return nil                 // «За всё время» не требует диапазона
        }
    }
    private func categoryObject(named name: String) -> Category? {
        // Если счёт не выбран — возвращаем nil
        guard let acc = selectedAccount else { return nil }
        // Явно вызываем first(where:), а не first + trailing-closure
        return allCategories.first(where: {
            // Поскольку account у Category может быть опциональным (Account?),
            // лучше сравнивать через optional chaining
            $0.account?.id == acc.id && $0.name == name
        })
    }

    private func defaultIconName(for categoryName: String) -> String {
        switch categoryName {
        case Category.uncategorizedName: return "circle.slash"
        case "Еда":           return "fork.knife"
        case "Транспорт":     return "car.fill"
        case "Дом":           return "house.fill"
        case "Одежда":        return "tshirt.fill"
        case "Здоровье":      return "bandage.fill"
        case "Питомцы":       return "pawprint.fill"
        case "Связь":         return "wifi"
        case "Развлечения":   return "gamecontroller.fill"
        case "Образование":   return "book.fill"
        case "Дети":          return "figure.walk"

        case "Зарплата":      return "wallet.bifold.fill"
        case "Дивиденды":     return "chart.line.uptrend.xyaxis"
        case "Купоны":        return "banknote"
        case "Продажи":       return "dollarsign.circle.fill"
        case "Премия":      return "star.circle.fill"
        case "Вклады":       return "dollarsign.bank.building.fill"
        case "Аренда":        return "house.fill"
        case "Подарки":        return "gift.fill"
        case "Подработка":        return "hammer.fill"

        default:              return "circle.slash"
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
        .sorted {
            if $0.totalAmount != $1.totalAmount {
                return $0.totalAmount > $1.totalAmount
            } else {
                return $0.category < $1.category
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 32) {
                    accountView
                    transactionTypeControl
                }

                ScrollView {
                    VStack(spacing: 20) {
                        timePeriodPicker
                        let emptyTexts: EmptyChartText = (selectedTransactionType == .expenses) ? .expenses : .income

                        Group {
                            if filteredTransactions.isEmpty {
                                EmptyPiePlaceholderView(
                                    texts: emptyTexts,
                                    amountText: "0,00\(currencySign)"
                                )
                            } else {
                                PieChartView(
                                    transactions: filteredTransactions,
                                    transactionType: selectedTransactionType,
                                    currencySign: currencySign
                                )
                                .transition(.opacity)   // появление диаграммы
                            }
                        }
                        .animation(.easeInOut, value: filteredTransactions.count)
                        categoryTags
                    }
                }
            }
            .navigationTitle("Мой Бюджет")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .background(.backgroundLightGray)
        }
        .onAppear {
             generateMissedRecurringTransactions()

             // Если пока нет выбранного — ставим первый из списка
            if selectedAccountID.isEmpty {
                selectedAccountID = accounts.first?.id.uuidString ?? ""
            }
             // Сразу заливаем дефолтные категории
             if let acc = selectedAccount {
                 Category.seedDefaults(for: acc, in: modelContext)
             }
         }
        .onChange(of: selectedAccountID) { newID in
            if let acc = selectedAccount {
                Category.seedDefaults(for: acc, in: modelContext)
            }
        }
        .onChange(of: accounts) { newAccounts in
            // если удалили текущий, переключаем на первого
            if !newAccounts.contains(where: { $0.id.uuidString == selectedAccountID }) {
                selectedAccountID = newAccounts.first?.id.uuidString ?? ""
            }
        }
    
            .sheet(isPresented: $isAddTransactionViewPresented) {
                AddTransactionView(account: selectedAccount) { addedType in
                    selectedTransactionType = addedType // ← здесь переключается сегмент
                }
            }

    }
    private var currencySign: String {
        // 1) Берём код валюты из выбранного счёта, или "RUB" по умолчанию
        let code = selectedAccount?.currency ?? "RUB"
        // 2) Ищем в словаре символ; если вдруг нет — fallback на сам код
        return currencySymbols[code] ?? code
    }


    /// Диапазон дат для подписи под заголовком (`nil` – если «За всё время»)
    private var periodCaption: String? {
        guard let (start, end) = periodRange(for: selectedTimePeriod) else { return nil }

        // «Сегодня» → одна дата
        if selectedTimePeriod == .today {
            return DateFormatter.rus.string(from: end, includeYear: true)          // «17 апр 2025»
        }

        // Диапазон
        let sameYear = Calendar.current.component(.year, from: start) ==
                       Calendar.current.component(.year, from: end)

        let left  = DateFormatter.rus.string(from: start, includeYear: !sameYear)
        let right = DateFormatter.rus.string(from: end,   includeYear: true)
        return "\(left) – \(right)"
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

                Picker("Выберите счет", selection: $selectedAccountID) {
                    ForEach(accounts, id: \.id) { acc in
                        Text(acc.name).tag(acc.id.uuidString)
                    }
                }
                .tint(.white).opacity(0.85) // Изменяет цвет выделенного текста на белый
            }

            VStack(spacing: 8) {
                Text("Баланс")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.subheadline)
                // 1) Получаем числовое значение баланса
                let value = saldo
                
                // 2) Преобразуем его в сокращённую строку (например "10 000", "1.2 млн")
                let amountText = value.toShortStringWithSuffix()
                
                // 3) Берём код валюты, если он есть, иначе "RUB"
                let currencyCode = selectedAccount?.currency ?? "RUB"
                
                // 4) Переводим код в символ
                let currencySign = currencySymbols[currencyCode] ?? currencyCode
                
                // 5) Всегда используем белый цвет, независимо от значения
                let color: Color = .white
                
                // 6) Убираем ручное добавление знака минус, так как toShortStringWithSuffix уже включает знак
                Text("\(amountText)\(currencySign)")
                    .foregroundColor(color)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontWeight(.bold)
            }


            Button {
                isAddTransactionViewPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.ring.dashed")
                        .imageScale(.large) 
                    Text("Добавить операцию")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(16)
            }
        }

        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(stops: [
                Gradient.Stop(color: Color(red: 79.0 / 255.0, green: 184.0 / 255.0, blue: 1.0), location: 0.0),
                Gradient.Stop(color: Color(red: 32.0 / 255.0, green: 60.0 / 255.0, blue: 1.0), location: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 3, y: 6)
    }

    private var categoryTags: some View {
        FlowLayout(spacing: 8) {
            ForEach(aggregatedTransactions) { agg in
                let bgColor = Color.colorForCategoryName(agg.category, type: selectedTransactionType)
                let textColor: Color = (bgColor == .yellow) ? .black : .white
                HStack(spacing: 2) {
                  // сначала пробуем кастомную иконку
                  if let cat = categoryObject(named: agg.category),
                     let icon = cat.iconName
                  {
                    Image(systemName: icon)
                      .font(.system(size: 14, weight: .medium))
                      .foregroundColor(textColor)

                  // если нет кастомной — пытаемся взять дефолтную
                  } else {
                    let sym = defaultIconName(for: agg.category)
                    if !sym.isEmpty {
                      Image(systemName: sym)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                    }
                  }
                    Text(agg.category)
                        .font(.body)
                        .lineLimit(1)

                    Text("\(agg.totalAmount.toShortStringWithSuffix())\(currencySign)")
                        .font(.headline)
                        .lineLimit(1)
                }
                .foregroundStyle(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(bgColor)
                .cornerRadius(20)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .center, spacing: 4) {

        HStack {
            Text("Период")
                .font(.title3).bold()
                .foregroundStyle(.primary)

            Spacer()

            Button {
                isShowingPeriodMenu.toggle()
            } label: {
                HStack(spacing: 2) {
                    Text(selectedTimePeriod.rawValue)
                        .foregroundColor(.appPurple.opacity(0.85))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.appPurple.opacity(0.85))
                }
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
            if let caption = periodCaption {
                Text(caption)
                    .font(.body.weight(.medium))   
                    .foregroundStyle(.black)
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
            .presentationDetents([.fraction(0.48)])
        }
    }
    private func generateMissedRecurringTransactions() {
        let now = Date()
        guard let account = selectedAccount else { return }

        for template in account.allRegularPayments where template.isActive {
            var nextDate = template.startDate

            while nextDate <= now && (template.endDate == nil || nextDate <= template.endDate!) {
                // Проверяем, не создана ли уже транзакция за эту дату
                let alreadyExists = account.allTransactions.contains {
                    $0.date.isSameDay(as: nextDate) &&
                    $0.category == template.name &&
                    $0.amount == template.amount
                }

                if !alreadyExists {
                    let tx = Transaction(
                        category: template.name,
                        amount: template.amount,
                        type: .expenses, // если нужно, храни тип в шаблоне
                        account: account
                    )
                    tx.date = nextDate
                    modelContext.insert(tx)
                }

                nextDate = template.frequency.nextDate(after: nextDate)
            }
        }

        try? modelContext.save()
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
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Свой период")
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
                        .frame(height: 44)
                        .background(Color(white: 1.0))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .tint(.appPurple)

                    DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .frame(height: 44)
                        .background(Color(white: 1.0))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .tint(.appPurple)
                }

                Button(action: {
                    onApply(startDate, endDate)
                    dismiss()
                }) {
                    Text("Применить")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.appPurple)
                        .foregroundStyle(.white)
                        .font(.headline)
                        .cornerRadius(16)
                        .padding()
                }
                .padding(.bottom, 24)

                Spacer() // Добавляем Spacer, чтобы растянуть содержимое
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Растягиваем VStack на весь экран
            .background(Color("BackgroundLightGray")) // Фон применяется ко всему содержимому
            .ignoresSafeArea() // Игнорируем безопасную область для всего NavigationStack
            .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
}


extension Double {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " " // пробел как разделитель тысяч
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func toShortStringWithSuffix() -> String {
        let absValue = abs(self)

        switch absValue {
        case 1_000_000_000...:
            let shortened = self / 1_000_000_000
            return String(format: "%.1f млрд", shortened)
        case 1_000_000...:
            let shortened = self / 1_000_000
            return String(format: "%.1f млн", shortened)
        default:
            // До 1 миллиона используем разделение пробелом
            return formattedWithSeparator
        }
    }
}

// Короткие вспомогатели
extension DateFormatter {
    static let rus: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        return df
    }()
    func string(from date: Date, includeYear: Bool) -> String {
        dateFormat = includeYear ? "d MMM yyyy" : "d MMM"
        return string(from: date)
    }
}
extension ReminderFrequency {
  func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
    // либо дублируете логику из ReminderFrequenci,
    // либо маппите на ваш enum-парсер
    guard let r = ReminderFrequenci(rawValue: self.rawValue) else { return date }
    return r.nextDate(after: date, calendar: calendar)
  }
}
extension Date {
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
}
struct EmptyPiePlaceholderView: View {
    let texts: EmptyChartText
    let amountText: String   // уже форматированная строка с символом

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 24)
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text(texts.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(amountText)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text(texts.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text(texts.hint)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)           // для анимации
    }
}

extension NumberFormatter {
    static let currencyRu: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = ""          // символ добавим сами
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.groupingSeparator = " "
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()
}

extension Double {
    func asMoney2() -> String {
        NumberFormatter.currencyRu.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
enum EmptyChartText {
    case expenses
    case income

    var title: String { self == .expenses ? "Расходы" : "Доходы" }
    var subtitle: String {
        self == .expenses ? "Нет расходов за выбранный период"
                          : "Нет доходов за выбранный период"
    }
    var hint: String {
        self == .expenses ? "Добавьте первую операцию — и диаграмма оживет 📊"
                          : "Добавьте первую операцию — и пусть ваш бюджет растёт 📈"
    }
}

