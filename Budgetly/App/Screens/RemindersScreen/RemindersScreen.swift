import SwiftUI
import SwiftData

struct RemindersScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reminders: [Reminder]
    @State private var isAddReminderViewPresented = false

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(reminders) { reminder in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(reminder.name)
                                    .font(.headline)
                                Text(reminder.date, style: .date) + Text(" ") + Text(reminder.date, style: .time)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Text(reminder.comment)
                                .font(.title3)
                                .foregroundStyle(.appPurple)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let reminder = reminders[index]
                            reminder.cancelNotification()
                            modelContext.delete(reminder)

                        }
                    }
                }
                Button(action: {
                    isAddReminderViewPresented = true
                }) {
                    Text("+ Создать")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.appPurple)
                        .foregroundStyle(.white)
                        .font(.headline)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                .padding()
                .sheet(isPresented: $isAddReminderViewPresented) {
                    AddReminderView()
                }
            }
            .navigationTitle("Напоминания")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
