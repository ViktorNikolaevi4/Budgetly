//
//  AccountsView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 14.11.2024.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var accountName: String = ""
    @State private var isShowingAlert = false
    @State var budgetViewModel: BudgetViewModel

    var body: some View {
        VStack {
            Text("Счета")
                .font(.headline)

            List {
                ForEach(budgetViewModel.accounts) { account in
                    Text(account.name)
                }
                .onDelete { indexSet in
                    budgetViewModel.accounts.remove(atOffsets: indexSet)
                }
            }

            Button(action: {
                isShowingAlert = true
            }) {
                Text("Добавить новый счет")
            }
            .alert("Новый счет", isPresented: $isShowingAlert) {
                TextField("Введите название счета", text: $accountName)
                Button("Создать", action: addAccount)
                Button("Отмена", role: .cancel, action: { accountName = "" })
            }
        }
    }

    private func addAccount() {
        guard !accountName.isEmpty else { return }
        let newAccount = Account(name: accountName)
        modelContext.insert(newAccount)
        budgetViewModel.accounts.append(newAccount)
        accountName = ""
    }
}
