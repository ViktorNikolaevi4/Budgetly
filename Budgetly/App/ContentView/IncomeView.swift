import SwiftUI
import SwiftData

struct IncomeView: View {

    @Query private var transactions: [Transaction]

    var body: some View {
        List {
            ForEach(transactions.filter { $0.type == .income }) { transaction in
                HStack {
                    Text(transaction.category)
                    Spacer()
                    Text("\(transaction.amount, specifier: "%.2f") ₽")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Доходы")
    }
}
