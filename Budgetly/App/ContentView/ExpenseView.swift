import SwiftUI
import SwiftData

struct ExpenseView: View {

    @Query private var transactions: [Transaction]

    var body: some View {
        List {
            ForEach(transactions.filter { $0.type == .expenses }) { transaction in
                HStack {
                    Text(transaction.category)
                    Spacer()
                    Text("\(transaction.amount, specifier: "%.2f") ₽")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Расходы")
    }
}
