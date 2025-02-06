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
        HStack {
            Text("Период:")
            Picker("Период", selection: $selectedTimePeriod) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .onChange(of: selectedTimePeriod) { _, newValue in
                if newValue == .custom {
                    isCustomPeriodPickerPresented = true
                }
            }
        }
        .onAppear {
            selectedTimePeriod = .allTime
        }
    }

    // MARK: - Список элементов (транзакций или активов) в зависимости от выбора
    @ViewBuilder
    private var listOfFilteredItems: some View {
        switch selectedSegment {
        case .income:
            // Показываем список доходов, отфильтрованных по периоду
            List(filteredIncomeTransactions) { tx in
                HStack {
                    Text(tx.category)
                    Spacer()
                    Text("\(tx.amount, specifier: "%.2f") ₽")
                        .foregroundColor(.green)
                }
            }
        case .expenses:
            // Показываем список расходов, отфильтрованных по периоду
            List(filteredExpenseTransactions) { tx in
                HStack {
                    Text(tx.category)
                    Spacer()
                    Text("\(tx.amount, specifier: "%.2f") ₽")
                        .foregroundColor(.red)
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
                        .foregroundColor(.blue)
                }
            }
        }
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

