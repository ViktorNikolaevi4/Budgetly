import SwiftUI
import Charts

struct PieChartView: View {
    @State private var selectedTimePeriod: String = "День"
    var transactions: [Transaction]

    var body: some View {
        VStack {
            Chart(transactions) { transaction in
                // Используем круговую диаграмму с сектором
                SectorMark(
                    angle: .value("Amount", transaction.amount),
                    innerRadius: .ratio(0.5),
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(by: .value("Category", transaction.category))
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

// Пример для превью
struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        PieChartView(transactions: [
            Transaction(id: UUID(), category: "Food", amount: 500.0, date: Date(), type: .expenses),
            Transaction(id: UUID(), category: "Transport", amount: 300.0, date: Date(), type: .expenses),
            Transaction(id: UUID(), category: "Entertainment", amount: 200.0, date: Date(), type: .expenses)
        ])
    }
}

