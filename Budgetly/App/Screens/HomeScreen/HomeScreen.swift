import SwiftUI
import Charts
import Observation
import SwiftData

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
    @Query private var accounts: [Account]

    @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .currentMonth
 //   @State private var customStartDate: Date = Date()
 //   @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false
    @State private var isShowingPeriodMenu = false

    @State private var appliedStartDate: Date?
    @State private var appliedEndDate: Date?

    @Environment(\.modelContext) private var modelContext

//    private let columns = [
//        GridItem(.adaptive(minimum: 110),
//                 spacing: 8,
//                 alignment: .leading)
//    ]
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

        guard let (start, end) = periodRange(for: selectedTimePeriod) else {
            return account.transactions
        }

        return account.transactions.filter { tx in
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

    /// Формат «1 апр» либо «1 апр 2025» в зависимости от того,
    /// совпадают ли годы начала и конца
//    private func format(_ date: Date,
//                        includeYear: Bool,
//                        formatter: DateFormatter) -> String {
//        formatter.dateFormat = includeYear ? "d MMM yyyy" : "d MMM"
//        return formatter.string(from: date)
//    }

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
                        PieChartView(transactions: filteredTransactions)
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
            //    seedDefaultCategoriesIfNeeded()

                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }
//            .sheet(isPresented: $isGoldBagViewPresented) {
//                GoldBagView()
//            }
            .sheet(isPresented: $isAddTransactionViewPresented) {
                AddTransactionView(account: selectedAccount) { addedType in
                    selectedTransactionType = addedType // ← здесь переключается сегмент
                }
            }
//            .sheet(isPresented: $isStatsViewPresented) {
//                StatsView()
//            }
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
                // "agg" — это AggregatedTransaction
                //    let isLong = agg.category.count > 10
                HStack() {
                    Text(agg.category)
                        .font(.body)
                        .lineLimit(1)
                    //  .minimumScaleFactor(0.8)
                    // .fixedSize(horizontal: false,
                    //    vertical: true)



                    Text("\(agg.totalAmount.toShortStringWithSuffix()) ₽")
                    // .foregroundColor(.primary)
                        .font(.headline)
                        .lineLimit(1)
                    // .minimumScaleFactor(0.8)
                }
                .foregroundStyle(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                //    .frame(maxWidth: .infinity)
                .background(bgColor)
                .cornerRadius(20)
                // .fixedSize()
                //  .gridCellColumns(isLong ? 2 : 1)
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
                        .cornerRadius(16)
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
