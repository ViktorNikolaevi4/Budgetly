//
//  RemindersView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 16.11.2024.
//

import SwiftUI
import SwiftData

struct RemindersView: View {
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
                                .font(.caption)
                                .foregroundStyle(.blue)
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
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .sheet(isPresented: $isAddReminderViewPresented) {
                    AddReminderView()
                }
            }
            .navigationTitle("Напоминания")
        }
    }
}
#Preview {
    RemindersView()
}
