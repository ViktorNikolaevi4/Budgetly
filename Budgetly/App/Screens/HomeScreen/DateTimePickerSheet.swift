import SwiftUI

struct DateTimePickerSheet: View {
    @Binding var date: Date
    @Binding var repeatRule: String
    @Environment(\.dismiss) private var dismiss

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
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
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

            Divider().padding(.vertical, 8)

            // Время
            HStack {
                Text("Время")
                    .font(.subheadline)
                Spacer()
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
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
        .background(Color("BackgroundLightGray"))
    }
}
