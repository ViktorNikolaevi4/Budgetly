import SwiftUI

struct NewCategoryView: View {
    let initialType: CategoryType
    let onSave: (_ name: String, _ icon: String?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String? = nil

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

    // для layout иконок
    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Введите название", text: $name)
                }
                Section("Иконка (опционально)") {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = (selectedIcon == icon ? nil : icon)
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color.appPurple : .gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
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
                    Button("Сохранить") {
                        onSave(name, selectedIcon)

                    }.foregroundStyle(.appPurple)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
