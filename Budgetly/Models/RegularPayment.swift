import Foundation
import SwiftData
import UserNotifications

@Model
class RegularPayment: Identifiable {
    var id: UUID = UUID() // Значение по умолчанию
    var name: String = "" // Значение по умолчанию
    private var frequencyRaw: String = ReminderFrequency.monthly.rawValue // Значение по умолчанию
    var startDate: Date = Date() // Значение по умолчанию
    var endDate: Date? = nil
    var amount: Double = 0.0 // Значение по умолчанию
    var comment: String = "" // Значение по умолчанию
    var isActive: Bool = true // Значение по умолчанию
    private var leadTimeRaw: String = ReminderLeadTime.none.rawValue // Значение по умолчанию

    var leadTime: ReminderLeadTime {
        get { ReminderLeadTime(rawValue: leadTimeRaw) ?? .none }
        set { leadTimeRaw = newValue.rawValue }
    }

    var frequency: ReminderFrequency {
        get { ReminderFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    @Relationship(inverse: \Account.regularPayments)
    var account: Account? // Обратная связь

    init(
        id: UUID = UUID(),
        name: String = "",
        frequency: ReminderFrequency = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        amount: Double = 0.0,
        comment: String = "",
        isActive: Bool = true,
        account: Account? = nil,
        leadTime: ReminderLeadTime = .none
    ) {
        self.id = id
        self.name = name
        self.frequencyRaw = frequency.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.amount = amount
        self.comment = comment
        self.isActive = isActive
        self.account = account
        self.leadTimeRaw = leadTime.rawValue
    }

    func scheduleNotification() { /* ... оставьте как есть ... */ }
    func cancelNotification() { /* ... оставьте как есть ... */ }
}

extension RegularPayment {
    func sheduleNotification() {
        // Создаем уведомление
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о платеже"
        content.body = "Платеж: \(name) на сумму \(String(format: "%.2f", amount)) ₽"
        content.sound = .default

        // Создаем триггер на основе даты начала
        let calendar = Calendar.current
        let componets = calendar.dateComponents([.year, .month, .day, .minute], from: startDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: componets, repeats: false)

        // Уникальный идентификатор уведомления
        let notificationID = "RegularPayment-\(id.uuidString)"

        // Создаем запрос на уведомление
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        // Добавляем запрос
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при добавлении уведомления: \(error)")
            } else {
                print("Уведомление запланировано: \(notificationID)")
            }
        }
    }

//    func cancelNotification() {
//        let notificationID = "RegularPayment-\(id.uuidString)"
//        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
//    }
}
