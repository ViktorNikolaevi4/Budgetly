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
    @State private var isShowingPeriodMenu = false

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
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 32) {
                            accountView
                            transactionTypeControl
                        }

                        timePeriodPicker

                        PieChartView(transactions: filteredTransactions)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(filteredTransactions) { transaction in
                                // Карточка
                                HStack(spacing: 8) {
                                    Text(transaction.category)
                                        .font(.body)
                                        .lineLimit(1)
                                     //   .fixedSize(horizontal: false, vertical: true)
                                   //     .truncationMode(.tail)
                                        .minimumScaleFactor(0.8)

                                    Text("\(transaction.amount.toShortStringWithSuffix()) ₽")                                        .foregroundColor(.primary)
                                        .font(.headline)
                                   //     .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(1)
                                    //    .truncationMode(.tail)
                                      //  .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                            //    .frame(maxWidth: .infinity)
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
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 6)
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
                isShowingPeriodMenu = true
            } label: {
                HStack {
                    Text(selectedPeriodTitle)  // Используем новое свойство здесь
                        .foregroundColor(.royalBlue.opacity(0.85))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.royalBlue.opacity(0.85))
                }
            }
            .confirmationDialog("Выберите период", isPresented: $isShowingPeriodMenu, titleVisibility: .visible) {
                ForEach(TimePeriod.allCases) { period in
                    Button(period.rawValue) {
                        selectedTimePeriod = period
                        if period == .custom {
                            isCustomPeriodPickerPresented = true
                        }
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: $customStartDate,
                endDate: $customEndDate
            )
            .presentationDetents([.medium])
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

                    DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                }
                // Кнопка "Применить"
                Button(action: {
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
            .environment(\.locale, Locale(identifier: "ru_RU"))
          //  .navigationBarTitleDisplayMode(.inline)
        }
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
