//
//  IncomeView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 09.11.2024.
//

import SwiftUI
import Observation

struct IncomeView: View {
    @State var budgetViewModel: BudgetViewModel

    var body: some View {
        List {
            ForEach(budgetViewModel.transactions.filter { $0.type == "Доходы" }) { transaction in
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
