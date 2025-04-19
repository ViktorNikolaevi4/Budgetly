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
        private static let incomeColorsKey = "AssignedColorsForIncome"
        private static let expensesColorsKey = "AssignedColorsForExpenses"

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
        static func colorForCategoryName(_ name: String, type: TransactionType) -> Color {
            // Выбираем ключ и словарь в зависимости от типа транзакции
            let key = type == .income ? incomeColorsKey : expensesColorsKey
            var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]

            // Если цвет уже назначен, возвращаем его
            if let colorComponents = assignedColors[name],
               colorComponents.count == 3 {
                return Color(red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2])
            }

            // Назначаем новый цвет
            let newColor: Color
            let totalCategories = assignedColors.count
            if totalCategories < predefinedColors.count {
                // Используем предопределённый цвет
                newColor = predefinedColors[totalCategories]
            } else {
                // Генерируем цвет на основе хэша
                newColor = colorFromHash(name)
            }

            // Сохраняем цвет в UserDefaults
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
            UIColor(newColor).getRed(&red, green: &green, blue: &blue, alpha: nil)
            assignedColors[name] = [Double(red), Double(green), Double(blue)]
            UserDefaults.standard.set(assignedColors, forKey: key)

            return newColor
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
