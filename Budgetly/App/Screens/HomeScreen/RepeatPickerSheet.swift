import SwiftUI

struct RepeatPickerSheet: View {
    @Binding var selectedRule: String
    @Environment(\.dismiss) private var dismiss

    private let allRules = [
        "Никогда",
        "Каждый день",
        "Каждую неделю",
        "Каждые 2 недели",
        "Каждый месяц",
        "Каждые 2 месяца",
        "Каждые 3 месяца",
        "Каждые 6 месяцев",
        "Каждый год"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Повтор")
                    .font(.headline)
                Spacer()
                // чтобы выровнять заголовок по центру
                Color.clear.frame(width: 24, height: 24)
            }
            .padding()

            Divider()

            // Список вариантов
            List {
                ForEach(allRules, id: \.self) { rule in
                    HStack {
                        Text(rule)
                        Spacer()
                        if rule == selectedRule {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appPurple)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRule = rule
                    }
                }
            }
            .listStyle(.plain)

            // Кнопка «Применить»
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

