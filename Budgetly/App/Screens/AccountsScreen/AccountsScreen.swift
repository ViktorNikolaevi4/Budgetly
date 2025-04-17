import SwiftUI
import SwiftData

struct AccountsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]

    @State private var accountName: String = ""
    @State private var isShowingAlert = false

    var body: some View {
        VStack {
            Text("Счета")
                .font(.headline)

            List {
                ForEach(accounts) { account in
                    Text(account.name)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(accounts[index])
                    }
                }
            }
            .listStyle(.plain)

            Button(action: {
                isShowingAlert = true
            }) {
                Text("Добавить новый счет")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPurple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)

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
        accountName = ""
    }
}
