import SwiftUI
import Charts

struct PieChartView: View {

    var transactions: [Transaction]

    @State private var selectedTimePeriod: String = "День"

    var body: some View {
        VStack {
            Chart(transactions) { transaction in
                SectorMark(
                    angle: .value("Amount", transaction.amount),
                    innerRadius: .ratio(0.7),
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(by: .value("Category", transaction.category))
            }
            .chartLegend(.hidden) // скрываем легенду
         //   .frame(width: 200, height: 200)
         //   .frame(width: 150, height: 150)
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

