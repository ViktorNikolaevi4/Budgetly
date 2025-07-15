import SwiftUI
import SwiftData

enum ReminderFrequency: String, CaseIterable, Identifiable {
    case once = "Один раз"
    case daily = "Каждый день"
    case weekly = "Каждую неделю"
    case biWeekly = "Каждые 2 недели"
    case monthly = "Каждый месяц"
    case biMonthly = "Каждые 2 месяца"
    case quarterly = "Каждый квартал"
    case semiAnnually = "Каждый полгода"
    case annually = "Каждый год"

    var id: String { self.rawValue }
}

struct CreateReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingPayment: RegularPayment?
    var account: Account

    @State private var paymentType: CategoryType = .expenses
    @State private var paymentName: String = ""
    @State private var reminderFrequency: ReminderFrequency = .once
    @State private var startDate = Date()
    @State private var includeEndDate = false
    @State private var endDate: Date? = nil
    @State private var amount: String = ""
    @State private var comment: String = ""

    init(account: Account, existingPayment: RegularPayment? = nil) {
        self.account = account
        self.existingPayment = existingPayment
        _paymentName = State(initialValue: existingPayment?.name ?? "")
        _reminderFrequency = State(initialValue: existingPayment?.frequency ?? .monthly)
        _startDate = State(initialValue: existingPayment?.startDate ?? Date())
        _endDate = State(initialValue: existingPayment?.endDate)
        _amount = State(initialValue: existingPayment?.amount != nil ? String(existingPayment!.amount) : "")
        _comment = State(initialValue: existingPayment?.comment ?? "")
    //    _paymentType = State(initialValue: existingPayment?.type ?? .expenses)
        _includeEndDate = State(initialValue: existingPayment?.endDate != nil)
    }

    var isFormValid: Bool {
        !paymentName.isEmpty && !amount.isEmpty
    }

    var body: some View {
        NavigationStack {
        VStack {
            HStack {
                Button(action: {
                    paymentType = .expenses
                }) {
                    Text("РАСХОДЫ")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(paymentType == .expenses ? Color.appPurple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                Button(action: {
                    paymentType = .income
                }) {
                    Text("ДОХОДЫ")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(paymentType == .income ? Color.appPurple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding()

            TextField("Наименование платежа", text: $paymentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Выбор периодичности
            Picker("Периодичность напоминания", selection: $reminderFrequency) {
                ForEach(ReminderFrequency.allCases) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }
            .tint(.appPurple)
            .pickerStyle(MenuPickerStyle()) // Используем меню для удобства
            .padding()

            DatePicker("Дата начала напоминания", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .padding()

            Toggle("Включить дату окончания", isOn: $includeEndDate)
                .padding()

            if includeEndDate {
                DatePicker("Дата окончания напоминания", selection: Binding(get: { endDate ?? Date() }, set: { endDate = $0 }), displayedComponents: [.date, .hourAndMinute])
                    .padding()
            }

            TextField("Сумма", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Комментарий", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                saveOrUpdateReminder()
                dismiss()
            }) {
                Text(existingPayment == nil ? "Создать" : "Обновить")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.appPurple)
                    .foregroundStyle(.white)
                    .font(.headline)
                    .cornerRadius(16)
            }
            .padding()
            .disabled(!isFormValid)
        }
        .navigationTitle(existingPayment == nil ? "Создать напоминание" : "Редактировать напоминание")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Кнопка-крестик в левом (или правом) верхнем углу
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss() // закрываем экран
                } label: {
                    Text("Закрыть")
                        .foregroundColor(.appPurple)
                }
            }
        }
        .padding()
    }
}

    private func saveOrUpdateReminder() {
        guard let amountValue = Double(amount) else { return }

        if let payment = existingPayment {
            // ——— обновляем старый
            payment.name       = paymentName
            payment.frequency  = reminderFrequency
            payment.startDate  = startDate
            payment.endDate    = includeEndDate ? endDate : nil
            payment.amount     = amountValue
            payment.comment    = comment
            payment.account = account

            payment.cancelNotification()
            payment.sheduleNotification()

            // Сохраняем изменения
            do {
                try modelContext.save()
            } catch {
                print("Ошибка при обновлении шаблона:", error)
            }

        } else {
            // ——— создаём новый
            let newReminder = RegularPayment(
                name: paymentName,
                frequency: reminderFrequency,
                startDate: startDate,
                endDate: includeEndDate ? endDate : nil,
                amount: amountValue,
                comment: comment,
                account: account
            )
            modelContext.insert(newReminder)
            newReminder.sheduleNotification()

            // Сохраняем новый
            do {
                try modelContext.save()
            } catch {
                print("Ошибка при создании шаблона:", error)
            }
        }

        // Закрываем экран
        dismiss()
    }
}


