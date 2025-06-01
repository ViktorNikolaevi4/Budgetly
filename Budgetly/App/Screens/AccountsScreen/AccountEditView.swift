import SwiftUI
import SwiftData

/// Список поддерживаемых валют (можно вынести куда-то в общий файл)


struct AccountEditView: View {
    // 1. Используем @Bindable, чтобы SwiftData знал, что мы правим поля модели
    @Bindable var account: Account

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Замыкание, которое вызовется, когда пользователь нажмёт «Удалить счёт» внутри этой формы
    var onDelete: (() -> Void)? = nil

    // Локальные @State для строк, если вы хотите работать с текстом “начальный баланс”:
    @State private var balanceText: String = ""

    let supportedCurrencies: [String] = ["RUB", "USD", "EUR", "GBP", "JPY", "CNY"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // ─── Бейдж валюты ────────────────────────────────────────────────────────
                // Рисуем его сразу под навигационным заголовком
                ZStack {
                    Circle()
                        .strokeBorder(Color.appPurple, lineWidth: 9)     // Обводка
                        .background(
                            Circle()
                                .foregroundColor(Color.lightPurprApple) // Полупрозрачный фон
                        )
                        .frame(width: 58, height: 58)

                    // Символ валюты (или пустая строка, если currency == nil)
                    Text(currencySymbols[account.currency ?? ""] ?? "")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
                Form {
                    Section {
                        // 1) Имя счёта
                        TextField("Название счета", text: $account.name)
                    }

                    Section {
                        // 2) Валюта
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
                        }

                        // 3) Начальный баланс (опционально)
                        HStack {
                            Text("Баланс")
                            Spacer()
                            // Здесь показываем отформатированный баланс (имя метода может отличаться у вас,
                            // но в примере мы используем account.formattedBalance)
                            Text(account.formattedBalance)
                                .foregroundColor(.secondary)
                        }

                        // 4) Toggle «Скрыть счёт»
                        Toggle(isOn: $account.isHidden) {
                            Text("Скрыть счет")
                        }
                    }

                    // В отдельном подразделе ниже кнопка «Удалить»
                    Section {
                        Button(role: .destructive) {
                            // Удаляем аккаунт:
                            deleteSelf()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Удалить счет")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Редактировать счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отменить") {
                        // Откатим любые несохранённые изменения (если нужно)
                        modelContext.rollback()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        // Сохраним изменения
                        do {
                            try modelContext.save()
                        } catch {
                            print("Ошибка при сохранении изменений в счет: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(account.name.isEmpty)
                }
            }
        }
        .onAppear {
            // Подставляем текущее значение в текстовое поле баланса:
            if let bal = account.initialBalance {
                balanceText = String(bal)
            }
        }
    }

    private func deleteSelf() {
        // Вызываем перед удалением переданное извне замыкание (чтобы экран AccountsScreen знал, что нужно закрыть sheet)
        onDelete?()

        // Собственно, удаляем всё связанное:
        for tx in account.transactions {
            modelContext.delete(tx)
        }
        for cat in account.categories {
            modelContext.delete(cat)
        }
        modelContext.delete(account)

        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении счета из EditView: \(error)")
        }

        // Закрываем экран
        dismiss()
    }
}
