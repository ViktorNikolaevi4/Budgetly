import SwiftUI
import SwiftData

struct AccountEditView: View {
    @Bindable var account: Account
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var onDelete: (() -> Void)? = nil
    let supportedCurrencies: [String] = ["RUB", "USD", "EUR", "GBP", "JPY", "CNY"]
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.appPurple, lineWidth: 9)
                        .background(Circle().foregroundColor(Color.lightPurprApple)) // Предполагаем адаптивный lightPurprApple
                        .frame(width: 58, height: 58)
                    Text(currencySymbols[account.currency ?? ""] ?? "")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white) // Белый для контраста
                }
                .padding(.top, 8)

                Form {
                    Section {
                        TextField("Название счета", text: $account.name)
                            .foregroundColor(Color(UIColor.label)) // Адаптивный цвет текста
                    }

                    Section {
                        HStack {
                            Text("Валюта")
                            Spacer()
                            Picker(selection: $account.currency) {
                                ForEach(supportedCurrencies, id: \.self) { cur in
                                    Text(cur).tag(cur as String?)
                                }
                            } label: {
                                Text(account.currency ?? "—")
                            }
                            .pickerStyle(.menu)
                            .tint(Color(UIColor.secondaryLabel)) // Адаптивный цвет для Picker (был .gray)
                        }

                        HStack {
                            Text("Баланс")
                            Spacer()
                            Text(account.formattedBalance)
                                .foregroundColor(Color(UIColor.secondaryLabel)) // Адаптивный вторичный цвет
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Удалить счет")
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground)) // Адаптивный фон для формы
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отменить") {
                        modelContext.rollback()
                        dismiss()
                    }
                    .foregroundColor(.appPurple)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        do { try modelContext.save() }
                        catch { print("Ошибка при сохранении изменений в счет: \(error)") }
                        dismiss()
                    }
                    .foregroundColor(account.name.isEmpty ? Color(UIColor.secondaryLabel) : .appPurple) // Адаптивный серый
                    .disabled(account.name.isEmpty)
                }
            }
            .alert("Удалить счет?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    deleteSelf()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Все связанные транзакции и категории будут удалены без возможности восстановления.")
            }
        }
        .foregroundStyle(Color(UIColor.label)) // Адаптивный цвет текста для всей вью
    }

    private func deleteSelf() {
        onDelete?()
        for tx in account.allTransactions { modelContext.delete(tx) }
        for cat in account.allCategories { modelContext.delete(cat) }
        modelContext.delete(account)
        try? modelContext.save()
        dismiss()
    }
}
