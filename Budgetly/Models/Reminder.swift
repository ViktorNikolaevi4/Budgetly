

import Foundation
import SwiftData
import UserNotifications

@Model
class Reminder: Identifiable {
    var id: UUID = UUID() // Значение по умолчанию
    var name: String = "" // Значение по умолчанию
    var date: Date = Date() // Значение по умолчанию
    var comment: String = "" // Значение по умолчанию

    init(
        id: UUID = UUID(),
        name: String = "",
        date: Date = Date(),
        comment: String = ""
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.comment = comment
    }
}
extension Reminder {
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание"
        content.body = "\(name) - \(comment)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let notificationID = "Reminder-\(id.uuidString)"
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при добавлении уведомления: \(error)")
            } else {
                print("Уведомление запланировано: \(notificationID)")
            }
        }
    }

    func cancelNotification() {
        let notificationID = "Reminder-\(id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
