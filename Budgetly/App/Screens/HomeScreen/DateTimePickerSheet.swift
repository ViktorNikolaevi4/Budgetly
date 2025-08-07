import SwiftUI

struct DateTimePickerSheet: View {
    @Binding var date: Date
    @Binding var repeatRule: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Отформатируем под ваш дизайн
    private let monthYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "LLLL yyyy"
        return fmt
    }()
    private let dayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "d"
        return fmt
    }()
    private let weekDaySymbols = Calendar.current.shortWeekdaySymbols // ["Sun","Mon",...]

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text("Дата")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Календарь
            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .accentColor(.appPurple)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            Divider().padding(.vertical, 8)

            // Время
            HStack {
                Text("Время")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .foregroundStyle(.appPurple)
            }
            .padding(.horizontal)

            Spacer()

            // Кнопка Применить
            Button("Применить") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.appPurple)
            .foregroundColor(.white)
            .cornerRadius(16)
            .padding()
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .accentColor(.appPurple)
    }
}
