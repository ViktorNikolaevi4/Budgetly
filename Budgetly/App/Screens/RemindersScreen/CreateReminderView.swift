import SwiftUI
import SwiftData

enum ReminderFrequency: String, CaseIterable, Identifiable {
    case daily         = "Каждый день"
    case weekly        = "Каждую неделю"
    case biWeekly      = "Каждые 2 недели"
    case monthly       = "Каждый месяц"
    case biMonthly     = "Каждые 2 месяца"
    case quarterly     = "Каждые 3 месяца"
    case semiAnnually  = "Каждый полгода"
    case annually      = "Каждый год"

    var id: String { rawValue }
}

struct CreateReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query private var allAccounts: [Account]

    var existingPayment: RegularPayment?
    var account: Account

    @State private var paymentType      : CategoryType        = .expenses
    @State private var paymentName      : String              = ""
    @State private var reminderFrequency: ReminderFrequency   = .monthly
    @State private var startDate        : Date                = Date()
    @State private var includeEndDate   : Bool                = false
    @State private var endDate          : Date?               = nil
    @State private var amount           : String              = ""
    @State private var comment          : String              = ""
    @State private var selectedAccount  : Account
    @State private var showingEndOptions: Bool                = false
    @State private var leadTime: ReminderLeadTime             = .none

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
        _selectedAccount  = State(initialValue: existingPayment?.account ?? account)
        _leadTime = State(initialValue: existingPayment?.leadTime ?? .none)
    }
    
    private var currencySign: String {
        let code = account.currency ?? "RUB"
        return currencySymbols[code] ?? code
    }

    private var isFormValid: Bool {
        !paymentName.isEmpty && !amount.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Тип платежа
                Section {
                    Picker("", selection: $paymentType) {
                        Text("Расходы").tag(CategoryType.expenses)
                        Text("Доходы").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .tint(.appPurple)
                }

                // MARK: Основные поля
                Section {
                    TextField("Название", text: $paymentName)
                    TextField("Комментарий", text: $comment)
                }

                // MARK: Сумма и счёт
                Section {
                    HStack {
                        Text("Сумма")
                        Spacer()
                        TextField("0,00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(currencySign)
                            .foregroundColor(.secondary)
                    }

                    Picker(selection: $selectedAccount, label: Text("Счет")) {
                        ForEach(allAccounts) { acct in
                            Text(acct.name).tag(acct)
                        }
                    }
                }

                // MARK: Даты и повтор
                Section {
                    HStack {
                        Text("Дата начала")
                        Spacer()
                        DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    HStack {
                        Text("Повтор")
                        Spacer()
                        Menu {
                            ForEach(ReminderFrequency.allCases) { freq in
                                Button(freq.rawValue) { reminderFrequency = freq }
                            }
                        } label: {
                            Text(reminderFrequency.rawValue)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        HStack {
                            Text("Конец повтора")
                            Spacer()
                            // Меняем Button+confirmationDialog на Menu
                            Menu {
                                // Пункт «Никогда»
                                Button(role: .destructive) {
                                    includeEndDate = false
                                    endDate = nil
                                } label: {
                                    Text("Никогда")
                                }
                                // Пункт «В дату»
                                Button {
                                    includeEndDate = true
                                    // по умолчанию через год от даты старта
                                    endDate = Calendar.current.date(
                                        byAdding: .year,
                                        value: 1,
                                        to: startDate
                                    )
                                } label: {
                                    Text("В дату")
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if includeEndDate, let end = endDate {
                                        Text(DateFormatter.short.string(from: end))
                                    } else {
                                        Text("Никогда")
                                    }
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                        // Если выбран «В дату», показываем DatePicker
                        if includeEndDate, let end = endDate {
                            DatePicker(
                                "Окончание",
                                selection: Binding(
                                    get: { endDate! },
                                    set: { endDate = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .padding(.top, 4)
                        }
                    }
                // MARK: Напоминание
                Section {
                     HStack {
                         Text("Напоминание")
                         Spacer()
                         Menu {
                             ForEach(ReminderLeadTime.allCases) { option in
                                 Button(option.rawValue) {
                                     leadTime = option
                                 }
                             }
                         } label: {
                             HStack(spacing: 4) {
                                 Text(leadTime.rawValue)
                                     .foregroundColor(leadTime == .none ? .secondary : .primary)
                                 Image(systemName: "chevron.down")
                                     .foregroundColor(.secondary)
                             }
                         }
                     }
                 }
             }
            .listStyle(.insetGrouped)
            .navigationTitle(existingPayment == nil ? "Создать напоминание" : "Редактировать напоминание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отменить") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPayment == nil ? "Добавить" : "Обновить") {
                        saveOrUpdateReminder()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    @MainActor
    private func saveOrUpdateReminder() {
        guard let value = Double(amount) else { return }

        if let payment = existingPayment {
            // обновляем
            payment.name       = paymentName
            payment.comment    = comment
            payment.amount     = value
            payment.frequency  = reminderFrequency
            payment.startDate  = startDate
            payment.endDate    = includeEndDate ? endDate : nil
            payment.account    = selectedAccount

            payment.cancelNotification()
            payment.sheduleNotification()

        } else {
            // создаём новый
            let newPayment = RegularPayment(
                name:       paymentName,
                frequency:  reminderFrequency,
                startDate:  startDate,
                endDate:    includeEndDate ? endDate : nil,
                amount:     value,
                comment:    comment,
                account:    selectedAccount
            )
            modelContext.insert(newPayment)
            newPayment.sheduleNotification()
        }

        try? modelContext.save()
    }
}

// MARK: — Форматтер в том же файле, чтобы он был видим
extension DateFormatter {
    static let short: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
}

enum ReminderLeadTime: String, CaseIterable, Identifiable, Codable {
    case none    = "Нет"
    case min5    = "За 5 минут"
    case min10   = "За 10 минут"
    case hour1   = "За 1 час"
    case day1    = "За 1 день"
    // добавьте, если нужно, ещё

    var id: String { rawValue }

    /// сколько секунд вычесть из даты платежа
    var seconds: TimeInterval {
        switch self {
        case .none:  return 0
        case .min5:  return 5 * 60
        case .min10: return 10 * 60
        case .hour1: return 60 * 60
        case .day1:  return 24 * 60 * 60
        }
    }
}
