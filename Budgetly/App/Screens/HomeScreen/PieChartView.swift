import SwiftUI
import Charts

struct PieChartView: View {

    var transactions: [Transaction]

    /// Общая сумма всех транзакций, которые приходят в этот PieChartView
    private var totalAmount: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    @State private var selectedTimePeriod: String = "День"

    private var currentType: TransactionType {
        transactions.first?.type ?? .income
    }

    var body: some View {
        ZStack {
            // Сама диаграмма
            Chart(transactions) { transaction in
                SectorMark(
                    angle: .value("Amount", transaction.amount),
                    innerRadius: .ratio(0.7),  // Можно менять, чтобы центр был больше/меньше
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(
                    Color.colorForCategoryName(transaction.category, type: transaction.type)
                )            }
            .chartLegend(.hidden)
            .frame(width: 128, height: 128) // Размер диаграммы при желании

            // Текст в центре
            VStack(spacing: 4) {
                // Например, пишем «Доходы» или «Расходы»
                let title = currentType == .income ? "Доходы" : "Расходы"
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                // Сама сумма
                Text("\(totalAmount, specifier: "%.0f")")
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
    private static let predefinedColors: [Color] = [.appPurple, .redApple, .orangeApple, .pinkApple, .blueApple, .yellowApple]

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

