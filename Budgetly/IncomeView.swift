import SwiftUI
import Observation

struct IncomeView: View {
    @State var budgetViewModel: BudgetViewModel
    
    var body: some View {
        List {
            ForEach(budgetViewModel.transactions.filter { $0.type == .income }) { transaction in
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
