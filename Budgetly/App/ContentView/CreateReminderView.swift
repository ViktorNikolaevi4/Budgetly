import SwiftUI
import SwiftData

struct CreateReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var paymentType: CategoryType = .expenses
    @State private var paymentName: String = ""
    @State private var reminderFrequency: String = "Каждый месяц"
    @State private var startDate = Date()
    @State private var includeEndDate = false // Переключатель для включения даты окончания
    @State private var endDate: Date? = nil
    @State private var amount: String = ""
    @State private var comment: String = ""

    var isFormValid: Bool {
        !paymentName.isEmpty && !amount.isEmpty
    }

    // Computed binding for endDate with a default value
    private var endDateBinding: Binding<Date> {
        Binding<Date>(
            get: { endDate ?? Date() },
            set: { endDate = $0 }
        )
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    paymentType = .expenses
                }) {
                    Text("РАСХОДЫ")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(paymentType == .expenses ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    paymentType = .income
                }) {
                    Text("ДОХОДЫ")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(paymentType == .income ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            TextField("Наименование платежа", text: $paymentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Периодичность напоминания", text: $reminderFrequency)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            DatePicker("Дата начала напоминания", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .padding()

            Toggle("Включить дату окончания", isOn: $includeEndDate)
                .padding()

            if includeEndDate {
                DatePicker("Дата окончания напоминания", selection: endDateBinding, displayedComponents: [.date, .hourAndMinute])
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
                saveReminder()
                dismiss()
            }) {
                Text("Создать")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(!isFormValid)
        }
        .navigationTitle("Создать напоминание")
        .padding()
    }

    private func saveReminder() {
        guard let amountValue = Double(amount) else { return }
        let newReminder = RegularPayment(
            name: paymentName,
            frequency: reminderFrequency,
            startDate: startDate,
            endDate: includeEndDate ? endDate : nil, // Добавление даты окончания, если она включена
            amount: amountValue,
            comment: comment
        )
        modelContext.insert(newReminder)
    }
}

