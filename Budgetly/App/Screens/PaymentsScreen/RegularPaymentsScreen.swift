import SwiftUI
import SwiftData

struct RegularPaymentsScreen: View {
    @AppStorage("selectedAccountID") private var selectedAccountID: String = ""
    @Query private var accounts: [Account]
    @Query private var allRegularPayments: [RegularPayment]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isCreateReminderViewPresented = false
    @State private var selectedPayment: RegularPayment?

    // Текущий аккаунт
    private var account: Account? {
        accounts.first { $0.id.uuidString == selectedAccountID }
    }

    // Фильтр регулярных платежей именно этого аккаунта
    private var regularPayments: [RegularPayment] {
        allRegularPayments.filter { $0.account?.id.uuidString == selectedAccountID }
    }

    // Символ валюты текущего аккаунта
    private var currencySign: String {
        let code = account?.currency ?? "RUB"
        return currencySymbols[code] ?? code
    }

    var body: some View {
        List {
            ForEach(regularPayments, id: \.id) { payment in
                paymentRow(payment)
                    .onTapGesture {
                        selectedPayment = payment
                        isCreateReminderViewPresented = true
                    }
            }
            .onDelete { indexSet in
                // Здесь удаляем только по swipe-to-delete
                for idx in indexSet {
                    let p = regularPayments[idx]
                    p.cancelNotification()
                    modelContext.delete(p)
                }
                try? modelContext.save()
            }
        }
        .navigationTitle("Регулярные платежи")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .foregroundStyle(.appPurple)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedPayment = nil
                    isCreateReminderViewPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(.appPurple)
            }
        }
        .sheet(isPresented: $isCreateReminderViewPresented) {
            if let acct = account {
                if let payment = selectedPayment {
                    CreateReminderView(account: acct, existingPayment: payment)
                } else {
                    CreateReminderView(account: acct)
                }
            } else {
                Text("Ошибка: счёт не найден")
                    .foregroundColor(.secondary)
            }
        }
    }

    // Вынесли ячейку в отдельный метод для чистоты кода
    @ViewBuilder
    private func paymentRow(_ payment: RegularPayment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .font(.body.bold())
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption)
                    Text(payment.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                let next = payment.frequency.nextDate(after: payment.startDate)
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

            VStack(spacing: 8) {
                Text("\(payment.amount.toShortStringWithSuffix())\(currencySign)")
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
                .tint(.appPurple)
            }
            .frame(width: 80)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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


