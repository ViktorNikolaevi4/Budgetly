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
                .foregroundStyle(by: .value("Category", transaction.category))
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

