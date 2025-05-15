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
                ForEach(regularPayments, id: \.id) { payment in
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      // 1) Название
                      Text(payment.name)
                        .font(.body.bold())

                      // 2) Частота
                      HStack(spacing: 4) {
                        Image(systemName: "repeat")
                          .font(.caption)
                        Text(payment.frequency.rawValue)
                          .font(.caption)
                          .foregroundColor(.secondary)
                      }

                      // 3) Следующая дата
                      let next = payment.frequency.nextDate(
                        after: payment.startDate,
                        calendar: .current
                      )
                      Text("След. \(DateFormatter.short.string(from: next))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                      // 4) Дата окончания (если включена)
                      if let end = payment.endDate {
                        Text("Окончание: \(DateFormatter.short.string(from: end))")
                          .font(.caption2)
                          .foregroundColor(.secondary)
                      }

                      // 5) Комментарий (если не пустой)
                      if !payment.comment.isEmpty {
                        Text(payment.comment)
                          .font(.caption2)
                          .foregroundColor(.secondary)
                          .lineLimit(2)
                      }
                    }

                    Spacer()

                  Toggle("", isOn: Binding(
                    get: { payment.isActive },
                    set: {
                      payment.isActive = $0
                      try? modelContext.save()
                    }
                  ))
                  .labelsHidden()

                  Button {
                    selectedPayment = payment
                    isCreateReminderViewPresented = true
                  } label: {
                    Image(systemName: "pencil")
                      .foregroundStyle(.appPurple)
                  }
                }
                .padding(.vertical, 8)
              }
              .onDelete { indexSet in
                for idx in indexSet {
                  let p = regularPayments[idx]
                  p.cancelNotification()
                  modelContext.delete(p)
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
            .cornerRadius(16)
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
private extension DateFormatter {
    static let short: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
}
