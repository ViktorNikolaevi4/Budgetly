import SwiftUI
import Observation

struct ExpenseView: View {
    @State var budgetViewModel: BudgetViewModel

    var body: some View {
        List {
            ForEach(budgetViewModel.transactions.filter { $0.type == .expenses }) { transaction in
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
