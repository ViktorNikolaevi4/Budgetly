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
        Dictionary(grouping: transactions, by: \.category)
            .map { category, txs in
                AggregatedData(
                    category: category,
                    totalAmount: txs.reduce(0) { $0 + $1.amount },
                    type: txs.first?.type ?? .income
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount } // вот тут по убыванию
    }

    var body: some View {
        ZStack {
            // Сама диаграмма
            Chart(aggregatedData) { data in
                SectorMark(
                    angle: .value("Amount", data.totalAmount),
                    innerRadius: .ratio(0.75),  // Можно менять, чтобы центр был больше/меньше
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(
                    Color.colorForCategoryName(data.category, type: data.type)
                )            }
            .chartLegend(.hidden)
            .frame(width: 165, height: 165) // Размер диаграммы при желании

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

    /// Возвращает или назначает цвет для (название категории, тип транзакции).
    static func colorForCategoryName(_ name: String, type: TransactionType) -> Color {
        if name == Category.uncategorizedName {
            return .gray.opacity(0.6)
        }

        let key = type == .income ? incomeColorsKey : expensesColorsKey
        var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]

        // Если цвет уже назначен, возвращаем его
        if let colorComponents = assignedColors[name],
           colorComponents.count == 3,
           validateColorComponents(colorComponents) {
            return Color(red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2])
        }

        // Назначаем новый цвет
        let newColor: Color
        let totalCategories = assignedColors.count
        if totalCategories < predefinedColors.count {
            newColor = predefinedColors[totalCategories]
        } else {
            newColor = colorFromHash(name)
        }

        // Сохраняем цвет в UserDefaults
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        UIColor(newColor).getRed(&red, green: &green, blue: &blue, alpha: nil)
        assignedColors[name] = [Double(red), Double(green), Double(blue)]
        UserDefaults.standard.set(assignedColors, forKey: key)

        return newColor
    }

    /// Устанавливает вручную выбранный цвет для категории
    static func setColor(_ color: Color, forCategory name: String, type: TransactionType) {
        let key = type == .income ? incomeColorsKey : expensesColorsKey
        var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
        assignedColors[name] = [Double(red), Double(green), Double(blue)]
        UserDefaults.standard.set(assignedColors, forKey: key)
    }

    /// Удаляет цвет категории из UserDefaults
    static func removeColor(forCategory name: String, type: TransactionType) {
        let key = type == .income ? incomeColorsKey : expensesColorsKey
        var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]
        assignedColors.removeValue(forKey: name)
        UserDefaults.standard.set(assignedColors, forKey: key)
    }

    /// Вспомогательный метод для генерации "стабильного" цвета по хэшу строки
    private static func colorFromHash(_ name: String) -> Color {
        let hash = name.hashValue
        let hue = Double((hash % 360 + 360) % 360) / 360.0
        let saturation = 0.5
        let brightness = 0.8
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// Проверяет валидность компонентов цвета
    private static func validateColorComponents(_ components: [Double]) -> Bool {
        guard components.count == 3 else { return false }
        return components.allSatisfy { $0 >= 0 && $0 <= 1 }
    }
}
