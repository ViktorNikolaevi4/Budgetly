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
    let transactionType: TransactionType

    let currencySign: String

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
                    type: transactionType
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
                    outerRadius: .ratio(1.0),
                    angularInset: 1
                )
                .cornerRadius(4)
                .foregroundStyle(
                    Color.colorForCategoryName(data.category, type: data.type)
                )
            }
            .chartLegend(.hidden)
            .frame(width: 165, height: 165) // Размер диаграммы при желании

            // Текст в центре
            VStack(spacing: 4) {
                            let title = transactionType == .income ? "Доходы" : "Расходы"
                            Text(title)
                                .font(.custom("SFPro-Regular", size: 15.0))
                                .foregroundColor(Color(white: 0.0, opacity: 0.5))
                                .multilineTextAlignment(.center)
                                .frame(height: 20.0, alignment: .center)
                            Text("\(totalAmount.toShortStringWithSuffix())\(currencySign)")
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

    static let predefinedColors: [Color] = [
        .appPurple, .redApple, .orangeApple, .yellow, .blueApple,
        .yellowApple, .pinkApple1, .lightPurprApple, .bolotoApple, .purpurApple,
        .boloto2, .boloto3, .gamno, .capu4Ino, .serota, .pupu, .yel3, .bezhev, .rozovo,.bordovo,
        .krasnenko
    ]

    /// Массив предопределённых цветов
    private static let presetColors: [String: Color] = {
        var result: [String: Color] = [:]
        let expenseNames = Category.defaultExpenseNames
        let incomeNames  = Category.defaultIncomeNames

        for (name, color) in zip(expenseNames, predefinedColors) {
            result[name] = color
        }
        for (name, color) in zip(incomeNames, predefinedColors.dropFirst(expenseNames.count)) {
            result[name] = color
        }
        // uncategorized всегда серый
        result[Category.uncategorizedName] = Color.gray.opacity(0.6)
        return result
    }()

    private static func loadAssignedColors(forKey key: String) -> [String:[Double]] {
        guard let raw = UserDefaults.standard.object(forKey: key) as? [String:Any] else {
            return [:]
        }
        var out: [String:[Double]] = [:]
        for (name, blob) in raw {
            if let arr = blob as? [Double] {
                out[name] = arr
            } else if let arr = blob as? [NSNumber] {
                out[name] = arr.map(\.doubleValue)
            } else if let arr = blob as? [Any] {
                let ds = arr.compactMap { ($0 as? NSNumber)?.doubleValue }
                if ds.count == arr.count {
                    out[name] = ds
                }
            }
        }
        return out
    }

    static func colorForCategoryName(_ name: String, type: TransactionType) -> Color {
        let key = type == .income ? incomeColorsKey : expensesColorsKey

        // 1) Если у пользователя уже сохранялся кастомный цвет — вернуть его
        let assigned = loadAssignedColors(forKey: key)
        if let comps = assigned[name], comps.count == 3 {
          return Color(red: comps[0], green: comps[1], blue: comps[2])
        }

        // 2) Если категория есть в вашем списке дефолтных — вернуть фиксированный preset-цвет
        if let preset = presetColors[name] {
          return preset
        }

        // 3) Во всех остальных случаях — стабильно сгенерировать новый, сохранить и вернуть
        let color = colorFromHash(name)
        setColor(color, forCategory: name, type: type)
        return color
      }
    static func setColor(_ color: Color, forCategory name: String, type: TransactionType) {
        guard name != Category.uncategorizedName else { return }
        let key = (type == .income) ? incomeColorsKey : expensesColorsKey
        var assigned = loadAssignedColors(forKey: key)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        assigned[name] = [Double(red), Double(green), Double(blue)]
        UserDefaults.standard.set(assigned, forKey: key)
    }

        static func removeColor(forCategory name: String, type: TransactionType) {
            let key = type == .income ? incomeColorsKey : expensesColorsKey
            var assignedColors = (UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]]) ?? [:]
            assignedColors.removeValue(forKey: name)
            UserDefaults.standard.set(assignedColors, forKey: key)
        }

        private static func colorFromHash(_ name: String) -> Color {
            let hash = name.hashValue
            let hue = Double((hash % 360 + 360) % 360) / 360.0
            let saturation = 0.5
            let brightness = 0.8
            return Color(hue: hue, saturation: saturation, brightness: brightness)
        }

        private static func validateColorComponents(_ components: [Double]) -> Bool {
            guard components.count == 3 else { return false }
            return components.allSatisfy { $0 >= 0 && $0 <= 1 }
        }
    }
