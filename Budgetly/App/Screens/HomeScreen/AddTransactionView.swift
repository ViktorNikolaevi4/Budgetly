import SwiftUI
import SwiftData

// MARK: - Страховка от NaN/∞ в layout
private struct SafeFrame: ViewModifier {
    var width: CGFloat?
    var height: CGFloat?
    func body(content: Content) -> some View {
        let w = width.map { ($0.isFinite && $0 > 0) ? $0 : 80 }
        let h = height.map { ($0.isFinite && $0 > 0) ? $0 : 68 }
        return content.frame(width: w, height: h)
    }
}
private extension View {
    func safeFrame(width: CGFloat?, height: CGFloat?) -> some View {
        modifier(SafeFrame(width: width, height: height))
    }
}

// MARK: - AddTransactionView
struct AddTransactionView: View {
    var account: Account?
    var onTransactionAdded: ((TransactionType) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // UI state
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

    @State private var selectedDate: Date = Date()
    @State private var repeatRule: String = "Никогда"

    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false

    // локальный снапшот категорий (вместо @Query)
    @State private var categoriesSnapshot: [Category] = []

    // MARK: Data loading
    @MainActor
    private func reloadCategories() {
        guard let acct = account else { categoriesSnapshot = []; return }
        // Без предикатов по optional keyPath — грузим всё и фильтруем в памяти
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        let all = (try? modelContext.fetch(descriptor)) ?? []
        categoriesSnapshot = all.filter { cat in
            cat.type == selectedType &&
            cat.account?.persistentModelID == acct.persistentModelID
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
        let cats = categoriesSnapshot
        return cats.sorted { lhs, rhs in
            if lhs.name == Category.uncategorizedName { return true }
            if rhs.name == Category.uncategorizedName { return false }
            let lhsTx = acct.allTransactions.filter { $0.type == txType && $0.category == lhs.name }
            let rhsTx = acct.allTransactions.filter { $0.type == txType && $0.category == rhs.name }
            if lhsTx.count != rhsTx.count { return lhsTx.count > rhsTx.count }
            let lhsSum = lhsTx.reduce(0) { $0 + $1.amount }
            let rhsSum = rhsTx.reduce(0) { $0 + $1.amount }
            if lhsSum != rhsSum { return lhsSum > rhsSum }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - FlowLayout (две строки, потом «Ещё»)
    struct FlowLayout: Layout {
        let spacing: CGFloat
        init(spacing: CGFloat = 8) { self.spacing = spacing }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
            let n = subviews.count
            guard n > 0 else { return .zero }
            let perRow = Int(ceil(Double(n) / 2.0))
            var maxWidth: CGFloat = 0
            var rowHeights: [CGFloat] = []
            for row in 0..<2 {
                let start = row * perRow
                let end = min(start + perRow, n)
                guard start < end else { break }
                let sizes = subviews[start..<end].map { $0.sizeThatFits(.unspecified) }
                let rowW = sizes.reduce(0) { $0 + $1.width } + CGFloat(max(sizes.count - 1, 0)) * spacing
                maxWidth = max(maxWidth, rowW.isFinite ? rowW : 0)
                rowHeights.append(sizes.map(\.height).max() ?? 0)
            }
            let totalHeight = rowHeights.reduce(0, +) + CGFloat(max(rowHeights.count - 1, 0)) * spacing
            return CGSize(width: maxWidth, height: totalHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
            let n = subviews.count
            guard n > 0 else { return }
            let perRow = Int(ceil(Double(n) / 2.0))
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

    private struct CatItem: Identifiable, Equatable {
        let id: String
        let category: Category?
    }

    private var visibleItems: [CatItem] {
        let cats = filteredCategories
        let maxQuick = 7
        var quick = Array(cats.prefix(maxQuick))
        if let selected = cats.first(where: { $0.name == selectedCategory }),
           !quick.contains(where: { $0.id == selected.id }) {
            if let i = quick.firstIndex(where: { $0.name == Category.uncategorizedName }) {
                quick[i] = selected
            } else {
                _ = quick.popLast()
                quick.insert(selected, at: 0)
            }
        }
        var items = quick.map { CatItem(id: $0.id.uuidString, category: $0) }
        items.append(CatItem(id: "more-\(account?.id.uuidString ?? "none")", category: nil))
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                // Верхняя панель
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
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isAmountFieldFocused ? Color.appPurple : .clear, lineWidth: 2)
                        )
                        .focused($isAmountFieldFocused)         // держим фокус
                        .foregroundColor(Color(UIColor.label))
                        .padding(.horizontal)
                        .onAppear {
                            DispatchQueue.main.async { isAmountFieldFocused = true }
                        }
                }
                .padding(.top, 0)

                // Категории (кастомный FlowLayout)
                ScrollView {
                    GeometryReader { geo in
                        let inset: CGFloat = 16
                        let minCellW: CGFloat = 80
                        let minGap: CGFloat = 4
                        let maxGap: CGFloat = 12

                        let safeWidth = max(geo.size.width, 1)
                        let contentW = max(safeWidth - inset * 2, 1)

                        let colsThatFit = max(1, Int(floor((contentW + minGap) / (minCellW + minGap))))
                        let cols = min(4, colsThatFit)

                        let rawGap = (contentW - minCellW * CGFloat(cols)) / CGFloat(max(cols - 1, 1))
                        let gap = max(minGap, min(maxGap, rawGap.isFinite ? rawGap : minGap))

                        let rawCellW = (contentW - gap * CGFloat(cols - 1)) / CGFloat(cols)
                        let safeCellW = (rawCellW.isFinite && rawCellW > 0) ? rawCellW : minCellW

                        FlowLayout(spacing: gap) {
                            ForEach(visibleItems) { item in
                                if let cat = item.category {
                                    Button { selectedCategory = cat.name } label: {
                                        CategoryBadge(category: cat, isSelected: selectedCategory == cat.name)
                                            .safeFrame(width: safeCellW, height: 68)
                                    }
                                } else {
                                    Button { showAllCategories = true } label: {
                                        VStack {
                                            Image(systemName: "ellipsis.circle").font(.title2)
                                            Text("Ещё").font(.caption)
                                        }
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(16)
                                        .safeFrame(width: safeCellW, height: 68)
                                    }
                                }
                            }
                        }
                        .transaction { $0.animation = nil } // без анимаций в лэйауте
                        .padding(.horizontal, inset)
                        .padding(.vertical, 10)
                        .padding(.bottom, 8)
                    }
                    .frame(minHeight: 0)
                }
                .id(selectedType) // пересоздаём сетку при смене типа

                // Дата и повтор
                HStack {
                    Button { showDateTimeSheet = true } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar").font(.subheadline)
                                Text("Дата").font(.subheadline)
                            }.foregroundStyle(.appPurple)
                            Text(dateTimeFormatter.string(from: selectedDate))
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.label))
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 10)
                        .frame(width: 176, height: 62, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                    }
                    Spacer()
                    Button { showRepeatSheet = true } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90").font(.subheadline)
                                Text("Повтор").font(.subheadline)
                            }.foregroundStyle(.appPurple)
                            Text(repeatRule)
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 10)
                        .frame(width: 176, height: 62, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
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
                .padding(.vertical, 6)

                // Кнопка «Добавить»
                Button(action: { saveTransaction() }) {
                    Text("Добавить")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.appPurple)
                        .cornerRadius(16)
                }
                .disabled(isSaving)
                .contentShape(Rectangle())
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemBackground))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Новая операция")
                        .fontWeight(.medium)
                        .foregroundStyle(Color(UIColor.label))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отменить") { dismiss() }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить") { saveTransaction() }
                        .disabled(isSaving)
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
            }
            .alert("Не удалось сохранить транзакцию", isPresented: $showSaveErrorAlert) {
                Button("ОК", role: .cancel) { }
            } message: { Text(saveErrorMessage) }
            .sheet(isPresented: $showAllCategories, onDismiss: { reloadCategories() }) {
                if let acct = account {
                    AllCategoriesView(
                        account: acct,
                        selected: $selectedCategory,
                        categoryType: selectedType
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { reloadCategories() }
        .onChange(of: selectedType) { _ in reloadCategories() }
        .onChange(of: account?.persistentModelID) { _ in reloadCategories() }
        .foregroundStyle(Color(UIColor.label))
    }

    // MARK: Save
    @MainActor
    private func saveTransaction() {
        guard !isSaving else { return }
        isSaving = true

        guard
            let account = account,
            let amountValue = amount.moneyValue(),
            !selectedCategory.isEmpty
        else {
            isSaving = false
            saveErrorMessage = "Введите сумму вида 128,80"
            showSaveErrorAlert = true
            return
        }

        let txDate = selectedDate
        let txType: TransactionType = (selectedType == .income) ? .income : .expenses

        let newTx = Transaction(category: selectedCategory, amount: amountValue, type: txType, account: account)
        newTx.date = txDate
        modelContext.insert(newTx)

        if let freq = ReminderFrequency(rawValue: repeatRule), freq != .never {
            let template = RegularPayment(
                name: selectedCategory,
                frequency: freq,
                startDate: txDate,
                endDate: (endOption == .onDate ? endDate : nil),
                amount: amountValue,
                comment: repeatComment,
                isActive: true,
                account: account
            )
            modelContext.insert(template)
        }

        do {
            try modelContext.serialSave()

            // спокойное закрытие
            isAmountFieldFocused = false
            showAllCategories = false
            showRepeatSheet = false
            showDateTimeSheet = false

            Task { @MainActor in
                await Task.yield()
                dismiss()
                await Task.yield()
                onTransactionAdded?(txType)
            }
        } catch {
            isSaving = false
            saveErrorMessage = error.localizedDescription
            showSaveErrorAlert = true
        }
    }
}

// MARK: - CategoryBadge
struct CategoryBadge: View {
    static let defaultNames =
        Category.defaultExpenseNames
      + Category.defaultIncomeNames
      + [Category.uncategorizedName]

    let category: Category
    let isSelected: Bool

    private static let badgeWidth: CGFloat = 84.3
    private static let badgeHeight: CGFloat = 68

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.colorForCategoryName(
                        category.name,
                        type: category.type == .income ? .income : .expenses
                    ))
                    .frame(width: 32, height: 32)

                if let custom = category.iconName {
                    Image(systemName: custom)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                } else if Self.defaultNames.contains(category.name) {
                    Image(systemName: iconName(for: category.name))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            Text(category.name)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .foregroundColor(Color(UIColor.label))
        }
        .frame(width: Self.badgeWidth, height: Self.badgeHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.appPurple : .clear, lineWidth: 2)
        )
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
        default: return "circle.slash"
        }
    }
}

// MARK: - AllCategoriesView (сам грузит категории)
struct AllCategoriesView: View {
    let account: Account
    @Binding var selected: String
    let categoryType: CategoryType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var categories: [Category] = []
    @State private var pendingDeleteIndex: IndexSet?
    @State private var isShowingDeleteAlert = false
    @State private var showNewCategorySheet = false

    @MainActor
    private func reloadCategories() {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        let all = (try? modelContext.fetch(descriptor)) ?? []
        categories = all.filter { cat in
            cat.type == categoryType &&
            cat.account?.persistentModelID == account.persistentModelID
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.id) { cat in
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
                            .foregroundColor(Color(UIColor.label))
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
                    isShowingDeleteAlert = true
                }
            }
            .listStyle(.plain)
            .background(Color(UIColor.systemBackground))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack { Image(systemName: "chevron.left"); Text("Назад") }
                            .foregroundStyle(.appPurple)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Категории")
                        Text(categoryType.rawValue)
                    }
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewCategorySheet = true } label: {
                        HStack { VStack { Text("Новая"); Text("Категория") }; Image(systemName: "plus.square") }
                            .foregroundStyle(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $showNewCategorySheet) {
                NewCategoryView(
                    initialType: categoryType,
                    onSave: { name, icon, color in
                        addNewCategory(name: name, icon: icon, color: color)
                        showNewCategorySheet = false
                    },
                    onCancel: { showNewCategorySheet = false }
                )
            }
            .alert("Удалить категорию?", isPresented: $isShowingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    if let indexSet = pendingDeleteIndex {
                        deleteCategories(at: indexSet)
                    }
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("При удалении категории все её транзакции тоже будут удалены.")
            }
        }
        .onAppear { reloadCategories() }
        .foregroundStyle(Color(UIColor.label))
    }

    // MARK: Actions
    private func addNewCategory(name: String, icon: String?, color: Color?) {
        guard !name.isEmpty else { return }
        let cat = Category(name: name, type: categoryType, account: account)
        cat.iconName = icon
        modelContext.insert(cat)

        if let color = color {
            let type: TransactionType = categoryType == .income ? .income : .expenses
            let key = type == .income ? "AssignedColorsForIncome" : "AssignedColorsForExpenses"
            var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: nil)
            assignedColors[name] = [Double(r), Double(g), Double(b)]
            UserDefaults.standard.set(assignedColors, forKey: key)
        }

        do {
            try modelContext.serialSave()
            selected = name
            reloadCategories()
        } catch {
            print("Ошибка сохранения категории: \(error)")
        }
    }

    private func deleteCategories(at indexSet: IndexSet) {
        for idx in indexSet {
            let cat = categories[idx]
            let toDelete = account.allTransactions.filter { $0.category == cat.name }
            toDelete.forEach { modelContext.delete($0) }
            modelContext.delete(cat)
            if selected == cat.name {
                selected = Category.uncategorizedName
            }
        }
        do {
            try modelContext.serialSave()
            reloadCategories()
        } catch {
            print("Ошибка при удалении категории и транзакций:", error)
        }
    }

    private func iconName(for categoryName: String) -> String {
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
        default: return "circle.slash"
        }
    }
}


