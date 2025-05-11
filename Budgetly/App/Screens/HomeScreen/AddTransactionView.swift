import SwiftUI
import SwiftData

struct AddTransactionView: View {
    var account: Account? // Связанный счёт
    var onTransactionAdded: ((TransactionType) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]
    @Environment(\.dismiss) var dismiss

    @State private var showAllCategories = false

    @State private var selectedType: CategoryType = .expenses
    @State private var amount: String = ""
    @FocusState private var isAmountFieldFocused: Bool
    @State private var selectedCategory: String = Category.uncategorizedName
    @State private var newCategory: String = ""
    @State private var showNewCategorySheet = false
  //  @State private var isShowingAlert = false // Флаг для отображения алерта
    @State private var hasEnsuredCategories = false

    @State private var selectedDate: Date = Date()
    @State private var repeatRule: String = "Никогда"

    private var categoriesForThisAccount: [Category] {
        guard let acct = account else { return [] }
        return allCategories.filter { $0.account.id == acct.id }
    }

    private let dateTimeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "d MMM yyyy • HH:mm"
        return fmt
    }()

    private var filteredCategories: [Category] {
      guard let acct = account else { return [] }

      // 1) приводим ваш CategoryType к TransactionType
      let txType: TransactionType = selectedType == .income
        ? .income
        : .expenses

      // 2) берём все категории этого счёта и выбранного типа
      let cats = allCategories
        .filter { $0.account.id == acct.id && $0.type == selectedType }

      // 3) сортируем по числу транзакций, по сумме, потом по имени
      return cats.sorted { lhs, rhs in
          // 3.1 «Без категории» всегда первой
           if lhs.name == Category.uncategorizedName { return true }
           if rhs.name == Category.uncategorizedName { return false }

        // транзакции lhs
        let lhsTx = acct.transactions.filter {
          $0.type == txType && $0.category == lhs.name
        }
        let rhsTx = acct.transactions.filter {
          $0.type == txType && $0.category == rhs.name
        }

        // 1) сравниваем по количеству
        if lhsTx.count != rhsTx.count {
          return lhsTx.count > rhsTx.count
        }
        // 2) по сумме
        let lhsSum = lhsTx.reduce(0) { $0 + $1.amount }
        let rhsSum = rhsTx.reduce(0) { $0 + $1.amount }
        if lhsSum != rhsSum {
          return lhsSum > rhsSum
        }
        // 3) и в конце — по алфавиту
        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
      }
    }

    private var visibleCategories: [Category?] {
        // все категории данного типа, уже отсортированные
        let cats = filteredCategories

        // если их не больше 7 — просто показываем все
        guard cats.count > 7 else {
            return cats.map { Optional($0) }
        }

        // берём первые 7
        var top7 = Array(cats.prefix(7))

        // если выбранная категория есть в общем списке,
        // но НЕ входит в эти top7 — подменяем ей первую ячейку
        if let sel = cats.first(where: { $0.name == selectedCategory }),
           !top7.contains(where: { $0.id == sel.id }) {
            top7[0] = sel
        }

        // и добавляем кнопку “Ещё”
        return top7.map { Optional($0) } + [nil]
    }

    struct FlowLayout: Layout {
        var spacing: CGFloat = 10

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            var totalHeight: CGFloat = 0
            var totalWidth: CGFloat = 0
            var lineWidth: CGFloat = 0
            var lineHeight: CGFloat = 0

            for size in sizes {
                if lineWidth + size.width > (proposal.width ?? 0) && lineWidth > 0 {
                    totalWidth = max(totalWidth, lineWidth)
                    totalHeight += lineHeight + spacing
                    lineWidth = 0
                    lineHeight = 0
                }
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            totalWidth = max(totalWidth, lineWidth)
            totalHeight += lineHeight

            return CGSize(width: max(totalWidth - spacing, 0), height: totalHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            var lineWidth: CGFloat = 0
            var lineHeight: CGFloat = 0
            var y: CGFloat = bounds.minY
            var x: CGFloat = bounds.minX

            for (index, subview) in subviews.enumerated() {
                let size = sizes[index]

                if lineWidth + size.width > bounds.width && lineWidth > 0 {
                    x = bounds.minX
                    y += lineHeight + spacing
                    lineWidth = 0
                    lineHeight = 0
                }

                subview.place(
                    at: CGPoint(x: x, y: y + (size.height / 2)),
                    anchor: .leading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )

                x += size.width + spacing
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 16) {
                    // Выбор «расходы / доходы»
                    Picker("Тип операции", selection: $selectedType) {
                        Text("Расходы").tag(CategoryType.expenses)
                        Text("Доходы").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .tint(.appPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                      .padding(.top, 8)
                    // Ввод суммы
                    TextField("Введите сумму", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white) // Серый фон с прозрачностью
                        .cornerRadius(10) // Закругленные углы
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isAmountFieldFocused ? Color.appPurple : .clear, lineWidth: 2)
                        )
                        .focused($isAmountFieldFocused)
                        .foregroundColor(.black) // Цвет вводимого текста
                        .padding(.horizontal)
                }.padding(.top, 0)
                //    .focused($isAmountFieldFocused)
                //                HStack {
                //                        // Выбор категории
                //                        Text("Категории")
                //                            .font(.headline)
                //                   Spacer()
                //                    Button {
                //                        isShowingAlert = true
                //                    } label: {
                //                        Image(systemName: "plus.circle")
                //                            .font(.title)
                //                            .foregroundStyle(.black)
                //                    }
                //                }
              ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(visibleCategories.enumerated()), id: \.offset) { idx, catOpt in
                            if let cat = catOpt {
                                // обычная категория
                                Button { selectedCategory = cat.name } label: {
                                    CategoryBadge(category: cat, isSelected: selectedCategory == cat.name)
                                }
                            } else {
                                // «Ещё»
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
                // MARK: – Дата и Повтор
                HStack(spacing: 8) {
                    // Кнопка для выбора даты
                    Button {
                        // TODO: здесь показываем DatePicker или ваш DatePickerSheet
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
                    // Кнопка для выбора повторения
                    Button {
                        // TODO: здесь показываем ваш UI для настройки повторений
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
                .padding(.horizontal)
                .padding(.vertical, 10)

                // Кнопка сохранения транзакции
                Button("Сохранить") {
                    saveTransaction()
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.appPurple)
                .foregroundStyle(.white)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color("BackgroundLightGray")) // фон
            .scrollContentBackground(.hidden) // Убираем фон NavigationStack
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Новая операция")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                }
                // кнопка «Отменить»
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отменить") { dismiss() }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
                // 🚀 новая кнопка «Добавить» для создания категории
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить") { showNewCategorySheet = true }
                        .font(.title3)
                        .foregroundStyle(.appPurple)
                }
            }
            .sheet(isPresented: $showAllCategories) {
                // внутри замыкания sheet можно использовать if let
                if let acct = account {
                    AllCategoriesView(
                        account: acct,
                        allCats: filteredCategories,
                        selected: $selectedCategory
                    )
                }
            }
            .sheet(isPresented: $showNewCategorySheet) {
                NewCategoryView(
                    initialType: selectedType,
                    onSave: { name, icon in
                        addNewCategory(name: name, icon: icon)
                        showNewCategorySheet = false
                    },
                    onCancel: {
                        showNewCategorySheet = false
                    }
                )
            }
            // Алерт для добавления новой категории
//            .alert("Новая категория", isPresented: $isShowingAlert) {
//                TextField("Введите новую категорию", text: $newCategory)
//                Button("Добавить", action: {
//                    addNewCategory()
//                })
//                Button("Отмена", role: .cancel, action: {
//                    newCategory = ""
//                })
//            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(.black)
        .onAppear {
            DispatchQueue.main.async {
                isAmountFieldFocused = true

            }
        }
    }

    // Функция для добавления новой категории
    private func addNewCategory(name: String, icon: String?) {
        guard let account = account, !name.isEmpty else { return }
        let cat = Category(name: name, type: selectedType, account: account)
        // если вы храните в Category ещё поле iconName:
        cat.iconName = icon
        modelContext.insert(cat)
        selectedCategory = name
        try? modelContext.save()
    }
    // Функция для удаления категории
    private func removeCategory(_ category: Category) {
        guard let account = account else { return }

        // 1. Находим все транзакции, у которых `transaction.category` совпадает с именем удаляемой категории
        let transactionsToRemove = account.transactions.filter { $0.category == category.name }

        // 2. Удаляем все эти транзакции из modelContext
        for transaction in transactionsToRemove {
            modelContext.delete(transaction)
        }

        // 3. Теперь удаляем саму категорию
        modelContext.delete(category)

        // 4. Сохраняем изменения
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении категории: \(error)")
        }
    }

    // Функция для сохранения транзакции
    private func saveTransaction() {
        guard
            let account = account,
            let amountValue = Double(amount),
            !selectedCategory.isEmpty
        else {
            return
        }
        // Дата транзакции (по умолчанию текущая)
        let newTransactionDate = Date()
        // Определяем тип (расход/доход)
        let transactionType: TransactionType = (selectedType == .income) ? .income : .expenses
        // Создаём новую транзакцию, не пытаясь искать существующую и не суммируя
        let newTransaction = Transaction(
            category: selectedCategory,
            amount: amountValue,
            type: transactionType,
            account: account
        )
        newTransaction.date = newTransactionDate
        // Добавляем в контекст и в массив транзакций счёта
        modelContext.insert(newTransaction)
        account.transactions.append(newTransaction)
        // Сохраняем
        do {
            try modelContext.save()
            onTransactionAdded?(transactionType)
            dismiss() // Закрываем текущий экран
        } catch {
            print("Ошибка при сохранении: \(error)")
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
                      .fill(
                        Color.colorForCategoryName(
                          category.name,
                          type: category.type == .income ? .income : .expenses
                        )
                      )
                        .frame(width: 32, height: 32)
                    // 1) если пользователь выбрал свою иконку — показываем её
                    if let icon = category.iconName {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                    // 2) иначе, если это одна из дефолтных категорий — рисуем её SF-иконку
                    } else if Self.defaultNames.contains(category.name) {
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
        case Category.uncategorizedName: return "tag"
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
        // … и так далее
        default:              return "tag.fill"
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
    @State private var selectedType: CategoryType = .expenses
    @State private var selectedCategory: String = Category.uncategorizedName

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var categoryToDelete: Category?
    @State private var isShowingDeleteAlert = false

    @State private var showNewCategorySheet = false


  //  static let defaultNames = Category.defaultExpenseNames + Category.defaultIncomeNames + [Category.uncategorizedName]

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
                              // пользовательская
                              Image(systemName: icon)
                                  .font(.system(size: 14, weight: .medium))
                                  .foregroundColor(.white)
                          } else if CategoryBadge.defaultNames.contains(cat.name) {
                              // одна из встроенных категорий
                              Image(systemName: iconName(for: cat.name))
                                  .font(.system(size: 14, weight: .medium))
                                  .foregroundColor(.white)
                          }
                          // больше никаких else
                      }

                    Text(cat.name)
                    Spacer()
                        // галочка выбранной
                        if cat.name == selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.appPurple)
                        }
                        // кнопка удаления
                        Button {
                            categoryToDelete = cat
                            isShowingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selected = cat.name
                        dismiss()
                    }

                }
            }
            .listStyle(.insetGrouped)
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
                        Text("Pасхода")
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
                    initialType: selectedType,
                    onSave: { name, icon in
                        addNewCategory(name: name, icon: icon)
                        showNewCategorySheet = false
                    },
                    onCancel: {
                        showNewCategorySheet = false
                    }
                )
            }
            .alert("Удалить категорию?", isPresented: $isShowingDeleteAlert, presenting: categoryToDelete) { cat in
                Button("Удалить", role: .destructive) {
                    deleteCategory(cat)
                }
                Button("Отменить", role: .cancel) { }
            } message: { cat in
                Text("При удалении категории «\(cat.name)» все её транзакции тоже будут удалены.")
            }
        }
    }
    private func addNewCategory(name: String, icon: String?) {
         guard !name.isEmpty else { return }
         let cat = Category(name: name, type: selectedType, account: account)
        // если вы храните в Category ещё поле iconName:
        cat.iconName = icon
        modelContext.insert(cat)
        selectedCategory = name
        try? modelContext.save()
    }

    private func deleteCategory(_ cat: Category) {
        // 1) удаляем все транзакции этого аккаунта в данной категории
        let txToDelete = account.transactions.filter { $0.category == cat.name }
        txToDelete.forEach { modelContext.delete($0) }

        // 2) удаляем саму категорию
        modelContext.delete(cat)

        // 3) если удалённая категория была выбрана — сбросим выбор на «Без категории»
        if selected == cat.name {
            selected = Category.uncategorizedName
        }

        // 4) сохраняем изменения
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении категории и транзакций:", error)
        }
    }
    func iconName(for categoryName: String) -> String {
        switch categoryName {
        case Category.uncategorizedName: return "tag"
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
        // … и так далее
        default:              return "tag.fill"
        }
    }
}
