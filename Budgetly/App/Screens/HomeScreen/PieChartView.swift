import SwiftUI
import Charts

struct AggregatedData: Identifiable {
    let id = UUID()
    let category: String
    let totalAmount: Double
    let type: TransactionType
}

struct PieChartView: View {

    var transactions: [Transaction]

    /// Общая сумма всех транзакций, которые приходят в этот PieChartView
    private var totalAmount: Double {
        aggregatedData.reduce(0) { $0 + $1.totalAmount }
    }

    @State private var selectedTimePeriod: String = "День"

    private var currentType: TransactionType {
        transactions.first?.type ?? .income
    }

    private var aggregatedData: [AggregatedData] {
        // Сгруппируем по названию категории
        let groupedByCategory = Dictionary(grouping: transactions, by: { $0.category })

        // Преобразуем каждую группу в AggregatedData
        return groupedByCategory.map { (category, groupTransactions) in
            let sum = groupTransactions.reduce(0) { $0 + $1.amount }
            let transactionType = groupTransactions.first?.type ?? .income
            return AggregatedData(
                category: category,
                totalAmount: sum,
                type: transactionType
            )
        }
    }


    var body: some View {
        ZStack {
            // Сама диаграмма
            Chart(aggregatedData) { data in
                SectorMark(
                    angle: .value("Amount", data.totalAmount),
                    innerRadius: .ratio(0.7),  // Можно менять, чтобы центр был больше/меньше
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(
                    Color.colorForCategoryName(data.category, type: data.type)
                )            }
            .chartLegend(.hidden)
            .frame(width: 128, height: 128) // Размер диаграммы при желании

            // Текст в центре
            VStack(spacing: 4) {
                // Например, пишем «Доходы» или «Расходы»
                let title = currentType == .income ? "Доходы" : "Расходы"
                Text(title)
                    .font(.custom("SFPro-Regular", size: 15.0))
                    .foregroundColor(Color(white: 0.0, opacity: 0.5))
                    .multilineTextAlignment(.center)
                    .frame(height: 20.0, alignment: .center)
                // Сама сумма
                Text("\(totalAmount.toShortStringWithSuffix()) ₽")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct CustomButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 170)
            .background(configuration.isPressed ? Color.gray : Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)

    }
}

extension Color {
    /// Словари для хранения уже назначенных цветов
    private static var assignedColorsForIncome: [String: Color] = [:]
    private static var assignedColorsForExpenses: [String: Color] = [:]

    /// Счётчики, сколько предопределённых цветов уже использовано
    private static var usedCountIncome = 0
    private static var usedCountExpenses = 0

    /// Массив предопределённых цветов
    private static let predefinedColors: [Color] = [.appPurple,
                                                    .redApple,
                                                    .orangeApple,
                                                    .yellow,
                                                    .blueApple,
                                                    .yellowApple,
                                                    .pinkApple1,
                                                    .lightPurprApple,
                                                    .bolotoApple,
                                                    .purpurApple]

    /// Возвращает цвет для (название категории, тип транзакции).
    /// - Если для этой категории ещё не назначен цвет:
    ///   - Если мы не исчерпали 6 «predefinedColors», выдаём следующий.
    ///   - Иначе генерируем цвет на основе хэша названия.
    /// - Если цвет уже назначен, возвращаем его.
    static func colorForCategoryName(_ name: String, type: TransactionType) -> Color {
        switch type {
        case .income:
            // Если уже есть цвет для этой категории доходов — возвращаем
            if let assigned = assignedColorsForIncome[name] {
                return assigned
            } else {
                let newColor: Color
                if usedCountIncome < predefinedColors.count {
                    newColor = predefinedColors[usedCountIncome]
                    usedCountIncome += 1
                } else {
                    // Генерируем цвет на основе хеша названия
                    newColor = colorFromHash(name)
                }
                assignedColorsForIncome[name] = newColor
                return newColor
            }

        case .expenses:
            // Аналогичная логика для расходов
            if let assigned = assignedColorsForExpenses[name] {
                return assigned
            } else {
                let newColor: Color
                if usedCountExpenses < predefinedColors.count {
                    newColor = predefinedColors[usedCountExpenses]
                    usedCountExpenses += 1
                } else {
                    newColor = colorFromHash(name)
                }
                assignedColorsForExpenses[name] = newColor
                return newColor
            }
        }
    }

    /// Вспомогательный метод для генерации "стабильного" цвета по хэшу строки
    private static func colorFromHash(_ name: String) -> Color {
        let hash = name.hashValue
        let hue = Double((hash % 360 + 360) % 360) / 360.0
        let saturation = 0.5
        let brightness = 0.8
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}


//// Пример для превью
//struct PieChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        PieChartView(transactions: [
//            Transaction(id: UUID(), category: "Food", amount: 500.0, date: Date(), type: .expenses),
//            Transaction(id: UUID(), category: "Transport", amount: 300.0, date: Date(), type: .expenses),
//            Transaction(id: UUID(), category: "Entertainment", amount: 200.0, date: Date(), type: .expenses)
//        ])
//    }
//}

