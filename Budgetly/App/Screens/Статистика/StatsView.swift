//
//  StatsView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 06.02.2025.
//

import SwiftUI
import SwiftData

enum StatsSegment: String, CaseIterable, Identifiable {
    case income = "Доходы"
    case expenses = "Расходы"
    case assets = "Активы"

    var id: String { rawValue }
}

struct StatsView: View {
    // Массив всех транзакций
    @Query private var transactions: [Transaction]
    // Массив всех активов
    @Query private var assets: [Asset]

    // Состояние выбора сегмента: Доходы / Расходы / Активы
    @State private var selectedSegment: StatsSegment = .income

    // Состояние выбора периода
    @State private var selectedTimePeriod: TimePeriod = .allTime
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var isCustomPeriodPickerPresented = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Сегментированный контрол для выбора: Доходы / Расходы / Активы
                segmentControl

                // Пикер периода (День, Неделя и т.д.)
                periodPicker

                // Список элементов внизу
                listOfFilteredItems
            }
            .padding()
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                // Кнопка-крестик слева
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        dismiss() // Закрываем Sheet
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.title)
//                            .foregroundColor(.red)
//                    }
//                }
//            }
        }
        // Если выбрали "Выбрать период", показываем выбор дат
        .sheet(isPresented: $isCustomPeriodPickerPresented) {
            CustomPeriodPickerView(
                startDate: $customStartDate,
                endDate: $customEndDate
            )
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

    // MARK: - Пикер периода (День, Неделя и т.д.)
    private var periodPicker: some View {
        Group {
            if selectedSegment != .assets {
                HStack {
                    Text("Период:")
                    Picker("Период", selection: $selectedTimePeriod) {
                        ForEach(TimePeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .tint(.appPurple)
                    .onChange(of: selectedTimePeriod) { _, newValue in
                        if newValue == .custom {
                            isCustomPeriodPickerPresented = true
                        }
                    }
                }
                .onAppear {
                    selectedTimePeriod = .allTime
                }
            } else {
                EmptyView() // Возвращаем пустую вью
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
        case .assets:
            // Показываем список всех активов (без фильтра по датам)
            List(assets) { asset in
                HStack {
                    VStack(alignment: .leading) {
                        Text(asset.name)
                            .font(.headline)
                        Text(asset.assetType?.name ?? "Без типа")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(asset.price, specifier: "%.2f") ₽")
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
        .sorted { $0.category < $1.category }
    }

    // MARK: - Фильтр доходов по периоду
    private var filteredIncomeTransactions: [Transaction] {
        transactions
            .filter { $0.type == .income }
            .filter(isInSelectedPeriod)
    }

    // MARK: - Фильтр расходов по периоду
    private var filteredExpenseTransactions: [Transaction] {
        transactions
            .filter { $0.type == .expenses }
            .filter(isInSelectedPeriod)
    }

    // MARK: - Сгруппированные доходы и расходы
    private var groupedIncomeTransactions: [(category: String, total: Double)] {
        groupedTransactions(filteredIncomeTransactions)
    }

    private var groupedExpenseTransactions: [(category: String, total: Double)] {
        groupedTransactions(filteredExpenseTransactions)
    }

    // MARK: - Проверка, попадает ли дата транзакции в выбранный период
    private func isInSelectedPeriod(_ transaction: Transaction) -> Bool {
        let now = Date()
        let calendar = Calendar.current
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
            return (transaction.date >= customStartDate && transaction.date <= customEndDate)
        }
    }
}
