import SwiftUI
import SwiftData

struct RegularPaymentsScreen: View {
    // UUID выбранного счёта хранится в UserDefaults
    @AppStorage("selectedAccountID") private var selectedAccountID: String = ""
    // Запрос всех аккаунтов из SwiftData
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var modelContext

    // Для открытия экрана создания/редактирования
    @State private var isCreateReminderViewPresented = false
    @State private var selectedPayment: RegularPayment?

    // Найти текущий Account по UUID
    private var account: Account? {
        accounts.first { $0.id.uuidString == selectedAccountID }
    }

    // И его регулярные платежи (пустой массив, если нет аккаунта)
    private var regularPayments: [RegularPayment] {
        account?.regularPayments.sorted { $0.startDate < $1.startDate } ?? []
    }

    var body: some View {
        List {
            ForEach(regularPayments, id: \.id) { payment in
                HStack {
                    // Левая колонка: имя, частота, даты и комментарий
                    VStack(alignment: .leading, spacing: 4) {
                        Text(payment.name)
                            .font(.body.bold())

                        HStack(spacing: 4) {
                            Image(systemName: "repeat").font(.caption)
                            Text(payment.frequency.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Следующая дата
                        let next = payment.frequency.nextDate(after: payment.startDate)
                        Text("След. \(DateFormatter.short.string(from: next))")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Дата окончания (если есть)
                        if let end = payment.endDate {
                            Text("Оконч.: \(DateFormatter.short.string(from: end))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Комментарий (если не пустой)
                        if !payment.comment.isEmpty {
                            Text(payment.comment)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Правая колонка: сумма + toggle
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
                .contentShape(Rectangle()) // чтобы весь ряд был тапаемым
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
                try? modelContext.save()
            }
        }
        .navigationTitle("Регулярные платежи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Кнопка "+" для создания нового
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedPayment = nil
                    isCreateReminderViewPresented = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Sheet для CreateReminderView
        .sheet(isPresented: $isCreateReminderViewPresented) {
            // если account не найден — показываем пустой текст
            if let acct = account {
                if let pay = selectedPayment {
                    CreateReminderView(account: acct, existingPayment: pay)
                } else {
                    CreateReminderView(account: acct)
                }
            } else {
                Text("Счет не выбран")
                    .padding()
            }
        }
    }
}

// Вспомогательный DateFormatter для короткой даты
private extension DateFormatter {
    static let short: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
}
