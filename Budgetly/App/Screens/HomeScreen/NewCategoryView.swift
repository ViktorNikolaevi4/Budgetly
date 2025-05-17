import SwiftUI

struct NewCategoryView: View {
    let initialType: CategoryType
    let onSave: (_ name: String, _ icon: String?, _ color: Color?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String? = nil
    @State private var selectedColor: Color? = .appPurple // Устанавливаем начальный выбранный цвет
    @State private var showIconPicker = false
    @State private var showColorPicker = true // Открываем цветовую палитру по умолчанию
    @FocusState private var isNameFieldFocused: Bool

    // Пример набора иконок
    private let icons = [
        "fork.knife", "car.fill", "house.fill",
        "tshirt.fill", "bandage.fill", "pawprint.fill",
        "wifi", "gamecontroller.fill", "book.fill", "figure.walk", "stethoscope",
        "pills.fill", "hands.and.sparkles.fill", "gift.fill", "airplane",
        "hammer.fill", "paintbrush.fill", "creditcard.fill", "takeoutbag.and.cup.and.straw.fill",
        "drop.fill", "scissors", "leaf.fill", "bicycle", "scooter", "bus", "tram",
        "fuelpump.fill", "play.tv.fill", "beats.headphones", "dumbbell.fill", "bolt.heart.fill",
        "music.note.list", "film.fill", "figure.strengthtraining.traditional",
        "antenna.radiowaves.left.and.right", "paintpalette.fill", "giftcard.fill", "star.fill",
        "basketball.fill", "puzzlepiece.fill", "tent.fill", "tree.fill", "shoe.fill",
        "comb.fill", "balloon.2.fill", "popcorn.fill", "graduationcap.fill", "lanyardcard.fill", "figure.run.treadmill",
        "figure.stand.dress.line.vertical.figure"
    ]
    private let incomeIcons = [
        "dollarsign.circle", "banknote", "creditcard.fill",
        "chart.line.uptrend.xyaxis", "wallet.pass.fill",
    ]
    private var iconsToShow: [String] {
        initialType == .expenses ? icons : incomeIcons
    }

    // Предопределённые цвета
    private static let predefinedColors: [Color] = [
        .appPurple, .redApple, .orangeApple, .yellow, .blueApple,
        .yellowApple, .pinkApple1, .lightPurprApple, .bolotoApple, .purpurApple,
        .boloto2, .boloto3, .gamno, .capu4Ino, .serota, .pupu, .yel3, .bezhev, .rozovo, .bordovo,
        .krasnenko
    ]

    // Сетка для кнопок
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var titleText: String {
        switch initialType {
        case .expenses:
            return "Новая категория расхода"
        case .income:
            return "Новая категория дохода"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(selectedColor ?? .appPurple)
                                .frame(width: 64, height: 64)
                            if let icon = selectedIcon {
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        TextField("Название", text: $name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10) // Закругление углов на радиус 10
                                    .fill(Color.gray.opacity(0.2))
                            )
                            .foregroundColor(.primary)
                            .focused($isNameFieldFocused)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                )

                // MARK: — Переключатель цвета
                Section {
                    Toggle("Цвет", isOn: $showColorPicker)
                        .toggleStyle(SwitchToggleStyle(tint: .appPurple))
                        .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                // MARK: — Цветовая палитра
                if showColorPicker {
                    Section {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Self.predefinedColors, id: \.self) { color in
                                Button {
                                    selectedColor = (selectedColor == color ? nil : color)
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            ZStack {
                                                if selectedColor == color {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 6)
                                                    Circle()
                                                        .stroke(Color.gray, lineWidth: 3)
                                                } else {
                                                    Circle()
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                }
                                            }
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                // MARK: — Переключатель иконок
                Section {
                    Toggle("Иконки", isOn: $showIconPicker)
                        .toggleStyle(SwitchToggleStyle(tint: .appPurple))
                        .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                // MARK: — Галерея иконок
                if showIconPicker {
                    Section {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(iconsToShow, id: \.self) { icon in
                                Button {
                                    selectedIcon = (selectedIcon == icon ? nil : icon)
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 38, height: 38)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedIcon == icon
                                                    ? Color.appPurple
                                                    : Color.gray.opacity(0.3),
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                        .foregroundStyle(.appPurple)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        if showColorPicker, let color = selectedColor {
                            let txType: TransactionType = (initialType == .income ? .income : .expenses)
                            Color.setColor(color, forCategory: name, type: txType)
                        }
                        onSave(
                            name,
                            showIconPicker ? selectedIcon : nil,
                            showColorPicker ? selectedColor : nil
                        )
                    }
                    .foregroundStyle(.appPurple)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNameFieldFocused = true
                }
            }
        }
    }
}
