import SwiftUI

/// Вариант окончания
enum EndOption: String, CaseIterable, Identifiable {
    case never = "Никогда"
    case onDate = "В дату"
    var id: String { rawValue }
}

struct RepeatPickerSheet: View {
    // MARK: – Входные биндинги
    @Binding var selectedRule: String
    @Binding var endOption: EndOption
    @Binding var endDate: Date
    @Binding var comment: String

    @Environment(\.dismiss) private var dismiss

    /// Все доступные правила повторения
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
            // MARK: – Заголовок
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Повтор")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            .padding()

            Divider()
                Form {
                    // MARK: – Секция с выбором правил
                    Section {
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
                            .onTapGesture { selectedRule = rule }
                        }
                    }

                    // MARK: – Секция «Конец повтора»
                    if selectedRule != "Никогда" {
                        Section {
                            Menu {
                                ForEach(EndOption.allCases) { opt in
                                    Button {
                                        endOption = opt
                                    } label: {
                                        HStack {
                                            Text(opt.rawValue)
                                            Spacer()
                                            if opt == endOption {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.appPurple)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Конец повтора")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(endOption.rawValue)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                            }
                            .padding(.vertical, 8)

                            if endOption == .onDate {
                                DatePicker("Окончание", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.vertical, 4)
                            }
                        }
                    }

                    // Добавляем отступ перед комментарием
                    // можно и Spacer(), но в Form проще сделать пустой Section с высотой
                    Section { EmptyView() }
                        .listRowBackground(Color.clear)
                        .frame(height: 16) // здесь регулируете пространство

                    // MARK: – Секция «Комментарий»
                    Section {
                        ZStack(alignment: .topLeading) {
                            if comment.isEmpty {
                                Text("Комментарий")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $comment)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .frame(minHeight: 80)
                        .background(Color.white)
                        .cornerRadius(8)
                        .listRowInsets(EdgeInsets())               // растянуть
                        .background(Color("BackgroundLightGray"))   // фон под полем
                    }
                }
                .listStyle(.insetGrouped)

                      .listStyle(.insetGrouped)

            // MARK: – Кнопка «Применить»
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
        .presentationDragIndicator(.visible)
    }
}


