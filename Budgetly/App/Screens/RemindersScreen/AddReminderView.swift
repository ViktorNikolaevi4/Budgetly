import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var date = Date()
    @State private var comment: String = ""

    var isFormValid: Bool {
        !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Основные данные")) {
                    TextField("Имя напоминания", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Дополнительно")) {
                    TextField("Комментарий", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Создать напоминание")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveReminder()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveReminder() {
        let newReminder = Reminder(name: name, date: date, comment: comment)
        modelContext.insert(newReminder)

        // Планируем уведомление
        newReminder.scheduleNotification()
    }
}

//
//#Preview {
//    AddReminderView()
//}
