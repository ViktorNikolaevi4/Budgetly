import SwiftUI
import SwiftData

struct AddTransactionView: View {
    var account: Account?
    var onTransactionAdded: ((TransactionType) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]
    @Environment(\.dismiss) var dismiss

    @State private var showAllCategories = false
    @State private var showRepeatSheet = false
    @State private var showDateTimeSheet = false

    @State private var repeatComment: String = ""
    @State private var endOption: EndOption = .never
    @State private var endDate: Date = Date()

    @State private var selectedType: CategoryType = .expenses
    @State private var amount: String = ""
    @FocusState private var isAmountFieldFocused: Bool
    @State private var selectedCategory: String = Category.uncategorizedName
    @State private var newCategory: String = ""
    @State private var showNewCategorySheet = false
    @State private var hasEnsuredCategories = false

    @State private var selectedDate: Date = Date()
    @State private var repeatRule: String = "Никогда"

    private var categoriesForThisAccount: [Category] {
        guard let acct = account else { return [] }
        return allCategories.filter {
            $0.account?.id == acct.id
        }
    }

    private let dateTimeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "d MMM yyyy • HH:mm"
        return fmt
    }()

    private var filteredCategories: [Category] {
        guard let acct = account else { return [] }
        let txType: TransactionType = (selectedType == .income) ? .income : .expenses
        // Сначала фильтруем по совпадению счёта и типа:
        let cats = allCategories.filter {
            $0.account?.id == acct.id && $0.type == selectedType
        }

        // Затем сортируем уже отфильтрованные:
        return cats.sorted { lhs, rhs in
            if lhs.name == Category.uncategorizedName { return true }
            if rhs.name == Category.uncategorizedName { return false }
            let lhsTx = acct.allTransactions.filter { $0.type == txType && $0.category == lhs.name }
            let rhsTx = acct.allTransactions.filter { $0.type == txType && $0.category == rhs.name }
            if lhsTx.count != rhsTx.count {
                return lhsTx.count > rhsTx.count
            }
            let lhsSum = lhsTx.reduce(0) { $0 + $1.amount }
            let rhsSum = rhsTx.reduce(0) { $0 + $1.amount }
            if lhsSum != rhsSum {
                return lhsSum > rhsSum
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }


    private var visibleCategories: [Category?] {
        let cats = filteredCategories
        let maxQuick = 7

        // если категорий мало — возвращаем все
        guard cats.count > maxQuick else {
            return cats.map { Optional($0) }
        }

        var quick = Array(cats.prefix(maxQuick))

        // Найдём выбранную категорию (в т.ч. только что созданную)
        if let selected = cats.first(where: { $0.name == selectedCategory }) {

            // Если её нет в первых maxQuick — вставим
            if !quick.contains(where: { $0.id == selected.id }) {

                // 1. Попробуем заменить «Без категории»
                if let idx = quick.firstIndex(where: { $0.name == Category.uncategorizedName }) {
                    quick[idx] = selected

                // 2. Иначе вытесним последний элемент
                } else {
                    quick.removeLast()
                    quick.insert(selected, at: 0)
                }
            }
        }

        // Возвращаем + кнопку «Ещё»
        return quick.map { Optional($0) } + [nil]
    }


    struct FlowLayout: Layout {
        let spacing: CGFloat

        init(spacing: CGFloat = 8) {
            self.spacing = spacing
        }

        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            let n = subviews.count
            guard n > 0 else { return .zero }

            // Сколько ячеек на строку (ceil(n/2))
            let perRow = Int(ceil(Double(n) / 2.0))

            // Посчитаем ширину каждой строки и высоту
            var maxWidth: CGFloat = 0
            var rowHeights: [CGFloat] = []

            for row in 0..<2 {
                let start = row * perRow
                let end = min(start + perRow, n)
                guard start < end else { break }
                let sizes = subviews[start..<end].map { $0.sizeThatFits(.unspecified) }
                let rowW = sizes.reduce(0) { $0 + $1.width } + CGFloat(sizes.count - 1) * spacing
                maxWidth = max(maxWidth, rowW)
                rowHeights.append(sizes.map(\.height).max() ?? 0)
            }

            let totalHeight = rowHeights.reduce(0, +) + CGFloat(rowHeights.count - 1) * spacing
            return CGSize(width: maxWidth, height: totalHeight)
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) {
            let n = subviews.count
            guard n > 0 else { return }

            let perRow = Int(ceil(Double(n) / 2.0))

            // Вычислим высоты строк, чтобы центровать элементы по вертикали
            let rowHeights: [CGFloat] = (0..<2).compactMap { row in
                let start = row * perRow, end = min(start + perRow, n)
                guard start < end else { return nil }
                return subviews[start..<end]
                    .map { $0.sizeThatFits(.unspecified).height }
                    .max()
            }

            var y = bounds.minY
            for row in 0..<rowHeights.count {
                let start = row * perRow
                let end = min(start + perRow, n)
                let sizes = subviews[start..<end].map { $0.sizeThatFits(.unspecified) }
                var x = bounds.minX

                for (i, subview) in subviews[start..<end].enumerated() {
                    let size = sizes[i]
                    // центрируем по вертикали в строке
                    let yOffset = (rowHeights[row] - size.height) / 2
                    subview.place(
                        at: CGPoint(x: x, y: y + yOffset),
                        anchor: .topLeading,
                        proposal: ProposedViewSize(size)
                    )
                    x += size.width + spacing
                }
                y += rowHeights[row] + spacing
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 16) {
                    Picker("Тип операции", selection: $selectedType) {
                        Text("Расходы").tag(CategoryType.expenses)
                        Text("Доходы").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .tint(.appPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    TextField("Введите сумму", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isAmountFieldFocused ? Color.appPurple : .clear, lineWidth: 2)
                        )
                        .focused($isAmountFieldFocused)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .task {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    print("Setting focus at \(Date())")
                                    isAmountFieldFocused = true
                                }
                            }
                }.padding(.top, 0)

                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(visibleCategories.enumerated()), id: \.offset) { idx, catOpt in
                            if let cat = catOpt {
                                Button { selectedCategory = cat.name } label: {
                                    CategoryBadge(category: cat, isSelected: selectedCategory == cat.name)
                                }
                            } else {
                                Button { showAllCategories = true } label: {
                                    VStack {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title2)
                                        Text("Ещё")
                                            .font(.caption)
                                    }
                                    .frame(width: 84, height: 68)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
//                .ignoresSafeArea(.keyboard, edges: .bottom)

                HStack {
                    Button {
                        showDateTimeSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                Text("Дата")
                                    .font(.subheadline)
                            } .foregroundStyle(.appPurple)
                            Text(dateTimeFormatter.string(from: selectedDate))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical)
                        .padding(.leading, 10)
                        .frame(width: 176, height: 64, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    }
                    Spacer()
                    Button {
                        showRepeatSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .font(.subheadline)
                                Text("Повтор")
                                    .font(.subheadline)
                            }.foregroundStyle(.appPurple)
                            Text(repeatRule)
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.vertical)
                        .padding(.leading, 10)
                        .frame(width: 176, height: 64, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    }
                }
                .sheet(isPresented: $showRepeatSheet) {
                    RepeatPickerSheet(
                        selectedRule: $repeatRule,
                        endOption: $endOption,
                        endDate: $endDate,
                        comment: $repeatComment
                    )
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showDateTimeSheet) {
                    DateTimePickerSheet(
                        date: $selectedDate,
                        repeatRule: $repeatRule
                    )
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                Button(action: {
                    saveTransaction()
                }) {
                    Text("Добавить")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.appPurple)
                        .cornerRadius(16)
                }
                .contentShape(Rectangle()) // Задаёт область нажатия для всей рамки
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        //    .contentShape(Rectangle())
            .background(Color("BackgroundLightGray"))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Новая операция")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отменить") { dismiss() }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить") { saveTransaction() }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
            }
            .sheet(isPresented: $showAllCategories) {
                if let acct = account {
                    AllCategoriesView(
                        account: acct,
                        allCats: filteredCategories,
                        selected: $selectedCategory,
                        categoryType: selectedType
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(.black)
    }

    private func addNewCategory(name: String, icon: String?, color: Color?) {
        guard let account = account, !name.isEmpty else { return }
        let cat = Category(name: name, type: selectedType, account: account)
        cat.iconName = icon
        modelContext.insert(cat)

        // Если выбран цвет, сохраняем его в UserDefaults
        if let color = color {
            let type: TransactionType = selectedType == .income ? .income : .expenses
            let key = type == .income ? "AssignedColorsForIncome" : "AssignedColorsForExpenses"
            var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
            UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
            assignedColors[name] = [Double(red), Double(green), Double(blue)]
            UserDefaults.standard.set(assignedColors, forKey: key)
        }

        selectedCategory = name
        try? modelContext.save()
    }

    private func removeCategory(_ category: Category) {
        guard let account = account else { return }
        let transactionsToRemove = account.allTransactions.filter { $0.category == category.name }
        for transaction in transactionsToRemove {
            modelContext.delete(transaction)
        }
        modelContext.delete(category)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении категории: \(error)")
        }
    }

    private func saveTransaction() {
         guard
             let account = account,
             let amountValue = Double(amount),
             !selectedCategory.isEmpty
         else { return }

         let txDate = Date()
         let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
         let newTx = Transaction(
             category: selectedCategory,
             amount: amountValue,
             type: transactionType,
             account: account
         )
         newTx.date = txDate
         modelContext.insert(newTx)

         // Привязываем транзакцию к счету (необязательно, SwiftData сделает это сам)
      //   account.transactions.append(newTx)

         // Если нужно шаблон регулярного платежа — создаём и привязываем к тому же account
         if repeatRule != EndOption.never.rawValue {
             let freq = ReminderFrequency(rawValue: repeatRule) ?? .daily
             let template = RegularPayment(
                 name: selectedCategory,
                 frequency: freq,
                 startDate: txDate,
                 endDate: endOption == .onDate ? endDate : nil,
                 amount: amountValue,
                 comment: repeatComment,
                 isActive: true,
                 account: account      // ← связали шаблон с этим счётом
             )
             modelContext.insert(template)
         }

         do {
             try modelContext.save()
             onTransactionAdded?(transactionType)
             dismiss()
         } catch {
             print("Ошибка при сохранении транзакции и шаблона: \(error)")
         }
     }
}

struct CategoryBadge: View {
    static let defaultNames =
        Category.defaultExpenseNames
      + Category.defaultIncomeNames
      + [Category.uncategorizedName]

    let category: Category
    let isSelected: Bool

    private static let badgeWidth: CGFloat = 84.3
    private static let badgeHeight: CGFloat = 68

  //  static let defaultNames = Category.defaultExpenseNames + Category.defaultIncomeNames + [Category.uncategorizedName]

    var body: some View {
            VStack(spacing: 6) {
                // цветной кружок + иконка
                ZStack {
                    Circle()
                      .fill(Color.colorForCategoryName(
                        category.name,
                        type: category.type == .income ? .income : .expenses
                      ))
                      .frame(width: 32, height: 32)

                    if let custom = category.iconName {
                      // Пользовательская иконка
                      Image(systemName: custom)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    } else if Self.defaultNames.contains(category.name) {
                      // Дефолтная SF-иконка
                      Image(systemName: iconName(for: category.name))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    }
                  }
                // название под иконкой
                Text(category.name)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: Self.badgeWidth,
                   height: Self.badgeHeight,
                   alignment: .center)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPurple : .clear, lineWidth: 2)
            )
        }
    func iconName(for categoryName: String) -> String {
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

    }

// Новый вью для показа всех категорий
struct AllCategoriesView: View {
    static let defaultNames =
        Category.defaultExpenseNames
      + Category.defaultIncomeNames
      + [Category.uncategorizedName]

    let account: Account
    let allCats: [Category]
    @Binding var selected: String
    let categoryType: CategoryType

    @State private var selectedCategory: String = Category.uncategorizedName

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var pendingDeleteIndex: IndexSet?
    @State private var categoryToDelete: Category?
    @State private var isShowingDeleteAlert = false
    @State private var showNewCategorySheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(allCats, id: \.id) { cat in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.colorForCategoryName(cat.name, type: cat.type == .income ? .income : .expenses))
                                .frame(width: 24, height: 24)

                            if let icon = cat.iconName {
                                Image(systemName: icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            } else if CategoryBadge.defaultNames.contains(cat.name) {
                                Image(systemName: iconName(for: cat.name))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(cat.name)
                        Spacer()
                        if cat.name == selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.appPurple)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selected = cat.name
                        dismiss()
                    }
                }
                .onDelete { indexSet in
                    pendingDeleteIndex = indexSet
                    if let first = indexSet.first {
                        categoryToDelete = allCats[first]
                    }
                    isShowingDeleteAlert = true
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() }
                    label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }.foregroundStyle(.appPurple)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Категории")
                        Text(categoryType.rawValue)
                    }
                    .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewCategorySheet = true
                    } label: {
                        HStack {
                            VStack {
                                Text("Новая")
                                Text("Категория")
                            }
                            Image(systemName: "plus.square")
                        }.foregroundStyle(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $showNewCategorySheet) {
                NewCategoryView(
                    initialType: categoryType,
                    onSave: { name, icon, color in // Теперь принимаем цвет
                        addNewCategory(name: name, icon: icon, color: color)
                        showNewCategorySheet = false
                    },
                    onCancel: {
                        showNewCategorySheet = false
                    }
                )
            }
            .alert("Удалить категорию?", isPresented: $isShowingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    if let indexSet = pendingDeleteIndex {
                        for idx in indexSet {
                            let cat = allCats[idx]
                            let toDelete = account.allTransactions.filter { $0.category == cat.name }
                            toDelete.forEach { modelContext.delete($0) }
                            modelContext.delete(cat)
                        }
                        try? modelContext.save()
                    }
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("При удалении категории все её транзакции тоже будут удалены.")
            }
        }
    }

    private func addNewCategory(name: String, icon: String?, color: Color?) {
        guard !name.isEmpty else { return }
        let cat = Category(name: name, type: categoryType, account: account)
        cat.iconName = icon
        modelContext.insert(cat)

        // Если выбран цвет, сохраняем его в UserDefaults
        if let color = color {
            let type: TransactionType = categoryType == .income ? .income : .expenses
            let key = type == .income ? "AssignedColorsForIncome" : "AssignedColorsForExpenses"
            var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
            UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
            assignedColors[name] = [Double(red), Double(green), Double(blue)]
            UserDefaults.standard.set(assignedColors, forKey: key)
        }

        selectedCategory = name
        try? modelContext.save()
    }

    private func deleteCategory(_ cat: Category) {
        let txToDelete = account.allTransactions.filter { $0.category == cat.name }
        txToDelete.forEach { modelContext.delete($0) }
        modelContext.delete(cat)
        if selected == cat.name {
            selected = Category.uncategorizedName
        }
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении категории и транзакций:", error)
        }
    }

    func iconName(for categoryName: String) -> String {
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
}
