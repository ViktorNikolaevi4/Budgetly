import Foundation
import SwiftData
import UserNotifications

@Model
class RegularPayment: Identifiable {
    var id: UUID
    var name: String
    private var frequencyRaw: String // Хранимое значение в виде строки
    var startDate: Date
    var endDate: Date?
    var amount: Double
    var comment: String
    var isActive: Bool // Новое свойство для состояния напоминания

    // Преобразование строки в enum и обратно
    var frequency: ReminderFrequency {
        get { ReminderFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    @Relationship(inverse: \Account.regularPayments)
    var account: Account?

    init(id: UUID = UUID(),
         name: String,
         frequency: ReminderFrequency,
         startDate: Date,
         endDate: Date?,
         amount: Double,
         comment: String,
         isActive: Bool = true,
         account: Account? = nil) {
        
        self.id = id
        self.name = name
        self.frequencyRaw = frequency.rawValue // Сохраняем как строку
        self.startDate = startDate
        self.endDate = endDate
        self.amount = amount
        self.comment = comment
        self.isActive = isActive
        self.account = account
    }
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

    func cancelNotification() {
        let notificationID = "RegularPayment-\(id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
