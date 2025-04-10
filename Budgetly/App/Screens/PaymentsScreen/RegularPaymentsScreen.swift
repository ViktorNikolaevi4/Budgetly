import SwiftUI
import SwiftData

struct RegularPaymentsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isCreateReminderViewPresented = false
    @State private var selectedPayment: RegularPayment?

    @Query private var regularPayments: [RegularPayment]

    var body: some View {
        VStack {
            List {
                ForEach(regularPayments) { payment in
                    HStack {
                        Text(payment.name)
                        Spacer()
                        Toggle(isOn: Binding(
                            get: { payment.isActive },
                            set: { newValue in
                                payment.isActive = newValue
                                try? modelContext.save() // Сохраняем изменения состояния
                            }
                        )) {
                            EmptyView()
                        }
                        .labelsHidden()

                        // Кнопка для редактирования
                        Button(action: {
                            selectedPayment = payment
                            isCreateReminderViewPresented = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.appPurple)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let payment = regularPayments[index]
                        payment.cancelNotification() // Отмена запланированного уведомления
                        modelContext.delete(payment) // Удаление из базы данных
                    }

                }
            }

            Button(action: {
                selectedPayment = nil // Установка в nil для создания нового платежа
                isCreateReminderViewPresented = true
            }) {
                Text("+ СОЗДАТЬ")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.appPurple)
            .foregroundStyle(.white)
            .font(.headline)
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .sheet(isPresented: $isCreateReminderViewPresented) {
                if let payment = selectedPayment {
                    // Открыть представление с редактированием
                    CreateReminderView(existingPayment: payment)
                } else {
                    // Открыть представление для создания нового платежа
                    CreateReminderView()
                }
            }
        }
        .navigationTitle("Регулярные платежи")
        .navigationBarTitleDisplayMode(.inline)

    }

}
