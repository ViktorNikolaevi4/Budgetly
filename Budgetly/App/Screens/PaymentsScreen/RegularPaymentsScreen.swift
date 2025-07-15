import SwiftUI
import SwiftData

struct RegularPaymentsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isCreateReminderViewPresented = false
    @State private var selectedPayment: RegularPayment?
    @Query private var regularPayments: [RegularPayment]

    var body: some View {
        List {
            ForEach(regularPayments, id: \.id) { payment in
                HStack {
                    // Левая часть: название, частота, даты, комментарий
                    VStack(alignment: .leading, spacing: 4) {
                        Text(payment.name).font(.body.bold())

                        HStack(spacing: 4) {
                            Image(systemName: "repeat").font(.caption)
                            Text(payment.frequency.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        let next = payment.frequency.nextDate(after: payment.startDate, calendar: .current)
                        Text("След. \(DateFormatter.short.string(from: next))")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let end = payment.endDate {
                            Text("Оконч.: \(DateFormatter.short.string(from: end))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if !payment.comment.isEmpty {
                            Text(payment.comment)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Правая часть: сумма и toggle
                    VStack(spacing: 8) {
                        Text("\(payment.amount.toShortStringWithSuffix()) ₽")
                            .font(.body.bold())
                            .foregroundColor(.primary)

                        Toggle("", isOn: Binding(
                            get: { payment.isActive },
                            set: {
                                payment.isActive = $0
                                try? modelContext.save()
                            }
                        ))
                        .labelsHidden()
                    }
                    .frame(width: 80)
                }
                .padding(.vertical, 8)
                // делаем всю строку «кликабельной»
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPayment = payment
                    isCreateReminderViewPresented = true
                }
            }


            .onDelete { indexSet in
                for idx in indexSet {
                    let p = regularPayments[idx]
                    p.cancelNotification()
                    modelContext.delete(p)
                }
            }
        }
        .navigationTitle("Регулярные платежи")
        .navigationBarTitleDisplayMode(.inline)
        // ✅ Кнопка “+” в тулбаре
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedPayment = nil
                    isCreateReminderViewPresented = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // переносим sheet сюда
        .sheet(isPresented: $isCreateReminderViewPresented) {
            if let payment = selectedPayment {
                CreateReminderView(existingPayment: payment)
            } else {
                CreateReminderView()
            }
        }
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
