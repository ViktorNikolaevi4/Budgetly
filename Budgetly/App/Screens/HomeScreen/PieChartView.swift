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
                .foregroundStyle(Color.colorForCategoryName(transaction.category))
            }
            .chartLegend(.hidden)
        //    .frame(width: 200, height: 200) // Размер диаграммы при желании

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
    /// Генерирует цвет на основе хеша строки.
    /// Для одинаковых названий категорий будет один и тот же цвет.
    static func colorForCategoryName(_ name: String) -> Color {
        // Берём хеш от строки
        let hash = name.hashValue

        // Из хеша извлекаем hue (оттенок) от 0 до 1
        // Например, берём остаток по модулю 360, чтобы получить угол в градусах, и делим на 360
        // Чтобы избежать отрицательных значений, можно взять абсолютное значение или "прокрутить" в позитив
        let hue = Double((hash % 360 + 360) % 360) / 360.0

        // saturation и brightness можно выбрать по вкусу
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

