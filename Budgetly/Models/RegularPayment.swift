import Foundation
import SwiftData

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

    init(id: UUID = UUID(),
         name: String,
         frequency: ReminderFrequency,
         startDate: Date,
         endDate: Date?,
         amount: Double,
         comment: String,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.frequencyRaw = frequency.rawValue // Сохраняем как строку
        self.startDate = startDate
        self.endDate = endDate
        self.amount = amount
        self.comment = comment
        self.isActive = isActive
    }
}
