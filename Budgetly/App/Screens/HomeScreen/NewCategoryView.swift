import SwiftUI

struct NewCategoryView: View {
    let initialType: CategoryType
    let onSave: (_ name: String, _ icon: String?, _ color: Color?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String? = nil
    @State private var selectedColor: Color? = nil
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @FocusState private var isNameFieldFocused: Bool

    // Пример набора иконок
    private let icons = [
        "fork.knife", "car.fill", "house.fill",
        "tshirt.fill", "bandage.fill", "pawprint.fill",
        "wifi", "gamecontroller.fill", "book.fill", "figure.walk", "stethoscope",
        "pills.fill", "hands.and.sparkles.fill", "gift.fill", "airplane",
        "hammer.fill", "paintbrush.fill", "creditcard.fill", "takeoutbag.and.cup.and.straw.fill",
        "drop.fill", "scissors", "leaf.fill", "bicycle", "scooter", "bus", "tram",
        "fuelpump.fill", "play.tv.fill", "beats.headphones", "dumbbell.fill","bolt.heart.fill",
        "music.note.list", "film.fill", "figure.strengthtraining.traditional",
        "antenna.radiowaves.left.and.right", "paintpalette.fill", "giftcard.fill", "star.fill",
        "basketball.fill", "puzzlepiece.fill", "tent.fill", "tree.fill", "shoe.fill",
        "comb.fill", "balloon.2.fill", "popcorn.fill", "graduationcap.fill", "lanyardcard.fill", "figure.run.treadmill",
        "figure.stand.dress.line.vertical.figure"
    ]

    // Массив предопределённых цветов (копируем из Color)
        private static let predefinedColors: [Color] = [
            .appPurple, .redApple, .orangeApple, .yellow, .blueApple,
            .yellowApple, .pinkApple1, .lightPurprApple, .bolotoApple, .purpurApple,
            .boloto2, .boloto3, .gamno, .capu4Ino, .serota, .pupu, .yel3, .bezhev, .rozovo, .bordovo,
            .krasnenko
        ]

    // для layout иконок
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
            NavigationStack {
                Form {
                    Section("Название") {
                        TextField("Введите название", text: $name)
                            .focused($isNameFieldFocused)
                            .padding(12)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isNameFieldFocused ? Color.appPurple : Color.clear, lineWidth: 4)
                            )
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    // Новая секция для выбора цвета
                    Section {
                        Toggle("Цвет", isOn: $showColorPicker)
                            .toggleStyle(SwitchToggleStyle(tint: .appPurple))
                            .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

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
                                                        // 1) внутренняя белая обводка
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: 6)
                                                        // 2) внешняя серая обводка
                                                        Circle()
                                                            .stroke(Color.gray, lineWidth: 3)
                                                    } else {
                                                        // обычная серая обводка, когда не выбрано
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
                    }
                    
                    Section {
                        Toggle("Иконки", isOn: $showIconPicker)
                            .toggleStyle(SwitchToggleStyle(tint: .appPurple))
                            .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    if showIconPicker {
                        Section {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(icons, id: \.self) { icon in
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
                    }
                }
                .navigationTitle("Новая категория")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена", action: onCancel)
                            .foregroundStyle(.appPurple)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            // 1) Сохраняем цвет из picker'а
                            if showColorPicker, let color = selectedColor {
                                let txType: TransactionType = (initialType == .income ? .income : .expenses)
                                Color.setColor(color, forCategory: name, type: txType)
                            }
                            // 2) Передаём управление наверх
                            onSave(name,
                                   showIconPicker ? selectedIcon : nil,
                                   showColorPicker ? selectedColor : nil)
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
