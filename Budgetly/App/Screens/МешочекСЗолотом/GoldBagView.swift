import SwiftUI
import SwiftData
import Charts

@Model
class AssetType: Identifiable {
    var id: UUID = UUID()
    var name: String = ""

    @Relationship(deleteRule: .cascade)
        var assets: [Asset]?

    init(name: String = "") {
        self.id = id
        self.name = name
    }
}

@Model
class Asset: Identifiable {
    var id: UUID = UUID() // Default value
    var name: String = "" // Default value
    var price: Double = 0.0 // Default value

    @Relationship(inverse: \AssetType.assets)
    var assetType: AssetType? // Relationship to AssetType with inverse

    init(id: UUID = UUID(), name: String = "", price: Double = 0.0, assetType: AssetType? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.assetType = assetType
    }
}

struct AssetGroup: Identifiable {
    let id: UUID
    let type: AssetType?
    let sum: Double
    let color: Color
}

struct GoldBagView: View {
    @Query private var assets: [Asset]
    @Query private var assetTypes: [AssetType]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isAddAssetPresented = false
    @State private var selectedAsset: Asset?
    private let noneTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    @State private var expandedTypes: Set<UUID> = []
    @State private var pendingDeleteAsset: Asset?
    @State private var isShowingDeleteAlert = false

    private var groupedAssetsByType: [AssetType?: [Asset]] {
        Dictionary(grouping: assets, by: { $0.assetType })
    }

    private var totalPrice: Double {
        assets.reduce(0) { $0 + $1.price }
    }

    private var assetGroups: [AssetGroup] {
      // 1) Строим сразу AssetGroup
      let groups = groupedAssetsByType.map { (type, list) -> AssetGroup in
        let sum = list.reduce(0) { $0 + $1.price }
        let id  = type?.id ?? noneTypeID
        // цвет можно проставить любым временным, его мы перезапишем после сортировки
        return AssetGroup(id: id, type: type, sum: sum, color: .gray)
      }

      // 2) Сортируем уже AssetGroup
      let sorted = groups.sorted { a, b in
        if a.sum != b.sum {
          return a.sum > b.sum
        } else {
          let nameA = a.type?.name ?? "Без типа"
          let nameB = b.type?.name ?? "Без типа"
          return nameA < nameB
        }
      }

      // 3) И только теперь раздаём цвета по индексу
      return sorted.enumerated().map { idx, group in
        let color: Color = group.type == nil
          ? .gray
          : Color.predefinedColors[idx % Color.predefinedColors.count]
        return AssetGroup(
          id: group.id,
          type: group.type,
          sum: group.sum,
          color: color
        )
      }
    }

    var body: some View {
        ZStack {
            // 1) Заливаем всю область серым
//            Color(UIColor.secondarySystemBackground)
//                .ignoresSafeArea()
            NavigationStack {
                Group {
                    if assets.isEmpty {
                        // Пустой стейт
                        EmptyStateView()
                    } else {
                        // Диаграмма + список
                        VStack() {
                            // 1) Круговая диаграмма
                            Chart(assetGroups) { item in
                                SectorMark(
                                    angle: .value("Сумма", item.sum),
                                    innerRadius: .ratio(0.75),
                                    outerRadius: .ratio(1.0),
                                    angularInset: 1
                                )
                                .cornerRadius(4)
                                .foregroundStyle(item.color)
                            }
                            .chartLegend(.hidden)
                            .frame(width: 180, height: 180)
                            .overlay(
                                Text("\(totalPrice.toShortStringWithSuffix()) ₽")
                                    .font(.title2).bold()
                                    .foregroundColor(.primary)
                            )
                            .padding()

                            // 2) Список групп и активов
                            List {
                                ForEach(assetGroups) { group in
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { expandedTypes.contains(group.id) },
                                            set: { newValue in
                                                if newValue {
                                                    expandedTypes.insert(group.id)
                                                } else {
                                                    expandedTypes.remove(group.id)
                                                }
                                            }
                                        )
                                    ) {
                                        ForEach(groupedAssetsByType[group.type] ?? []) { asset in
                                            Button { selectedAsset = asset } label: {
                                                HStack {
                                                    Text(asset.name)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Text("\(asset.price, specifier: "%.2f") ₽")
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.vertical, 4)
                                            }
                                            .tint(.primary)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    pendingDeleteAsset = asset
                                                    isShowingDeleteAlert = true
                                                } label: {
                                                    Label("Удалить", systemImage: "trash")
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(group.color)
                                                .frame(width: 10, height: 10)
                                            Text(group.type?.name ?? "Без типа")
                                                .font(.title3).bold()
                                                .foregroundColor(.primary)
                                            Spacer()
                                            HStack(spacing: 6) {
                                                Text("\(group.sum.toShortStringWithSuffix()) ₽")
                                                Circle()
                                                    .frame(width: 4, height: 4)
                                                    .foregroundColor(.gray.opacity(0.6))
                                                Text(String(format: "%.1f%%", group.sum / totalPrice * 100))
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }.listRowBackground(Color.primary)
                        }
                    }
                }
                // Навигационная панель (заголовок + кнопка "+")
                .navigationTitle("Мои Инвестиции")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isAddAssetPresented = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundStyle(.appPurple)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        // Алерт удаления
        .alert(
            "Подтвердить удаление",
            isPresented: $isShowingDeleteAlert
        ) {
            Button("Удалить", role: .destructive) {
                if let asset = pendingDeleteAsset {
                    delete(asset: asset)
                }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы уверены, что хотите удалить этот актив?")
        }
        // Листы для создания/редактирования
        .sheet(isPresented: $isAddAssetPresented) {
            AddOrEditAssetView(
                draftAsset: nil,
                assetTypes: assetTypes
            ) { name, price, type in
                let newAsset = Asset(name: name, price: price, assetType: type)
                modelContext.insert(newAsset)
                try? modelContext.save()
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedAsset) { asset in
            AddOrEditAssetView(
                draftAsset: asset,
                assetTypes: assetTypes
            ) { name, price, type in
                asset.name = name
                asset.price = price
                asset.assetType = type
                try? modelContext.save()
            }
            .presentationDetents([.medium])
        }
        // Подгружаем дефолтные типы
        .onAppear {
            createDefaultAssetTypesIfNeeded()
        }
    }



private func delete(asset: Asset) {
    modelContext.delete(asset)
    try? modelContext.save()
}

private func createDefaultAssetTypesIfNeeded() {
    let defaultNames = ["Акции", "Облигации", "Недвижимость"]
    let existing = Set(assetTypes.map(\.name))
    for name in defaultNames where !existing.contains(name) {
        modelContext.insert(AssetType(name: name))
    }
    try? modelContext.save()
  }
}

// AddOrEditAssetView остаётся без изменений
struct AddOrEditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme // Для проверки текущей темы, если нужно

    let draftAsset: Asset?
    let assetTypes: [AssetType]
    let onSave: (String, Double, AssetType?) -> Void

    @State private var name: String
    @State private var price: Double
    @State private var typeSelection: TypeSelection = .none
    @State private var isShowingNewTypeAlert = false
    @State private var newTypeName = ""
    @State private var isShowingDeleteAlert = false

    init(
        draftAsset: Asset?,
        assetTypes: [AssetType],
        onSave: @escaping (String, Double, AssetType?) -> Void
    ) {
        self.draftAsset = draftAsset
        self.assetTypes = assetTypes
        self.onSave = onSave
        _name = State(initialValue: draftAsset?.name ?? "")
        _price = State(initialValue: draftAsset?.price ?? 0.0)
        if let existingType = draftAsset?.assetType {
            _typeSelection = State(initialValue: .existing(existingType))
        }
    }

    var body: some View {
        ZStack {
            // Фон всей вью
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Ручка
                    Capsule()
                        .frame(width: 36, height: 5)
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)

                    // Заголовок
                    HStack {
                        Text(draftAsset == nil ? "Новый актив" : name)
                            .font(.title).bold()
                            .foregroundColor(.primary) // Адаптивный цвет текста
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary) // Серый в обеих темах
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 16) {
                        // Название
                        HStack {
                            TextField("Введите название", text: $name)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .foregroundColor(.primary)
                        }
                        .background(Color(.secondarySystemBackground)) // Адаптивный фон поля
                        .cornerRadius(16)

                        // Тип
                        HStack {
                            Text("Выберите тип")
                                .foregroundColor(.primary)
                            Spacer()
                            Picker("", selection: $typeSelection) {
                                Text("Без типа").tag(TypeSelection.none)
                                ForEach(assetTypes, id: \.id) { t in
                                    Text(t.name).tag(TypeSelection.existing(t))
                                }
                                Text("Новый тип…").tag(TypeSelection.newType)
                            }
                            .pickerStyle(.menu)
                            .tint(.accentColor) // Заменяем .appPurple на системный акцентный цвет
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)

                        // Стоимость
                        HStack {
                            Text("Стоимость")
                                .foregroundColor(.primary)
                            Spacer()
                            TextField("0", value: $price, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 120)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)

                        if draftAsset != nil {
                            Text("Если цена изменилась — просто обновите её 📈")
                                .font(.footnote)
                                .foregroundColor(.secondary) // Адаптивный серый цвет
                                .padding(.horizontal, 16)
                        }
                    }

                    .padding(.horizontal)
                    Spacer()
                    // Кнопки
                    VStack(spacing: 16) {
                        // Сохранить / Добавить
                        Button(action: saveAndDismiss) {
                            Text(draftAsset == nil ? "Добавить" : "Сохранить")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundColor(.white)
                                .background(
                                    name.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.gray.opacity(0.5)
                                        : .accentColor // Заменяем .appPurple на системный акцент
                                )
                                .cornerRadius(16)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                        // Удалить (показываем только при редактировании)
                        if draftAsset != nil {
                            Button(role: .destructive) {
                                isShowingDeleteAlert = true
                            } label: {
                                Text("Удалить актив")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .foregroundColor(.red)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .alert(
                "Подтвердить удаление",
                isPresented: $isShowingDeleteAlert
            ) {
                Button("Удалить", role: .destructive) {
                    deleteAsset()
                }
                Button("Отмена", role: .cancel) {
                    // Просто закроет алерт
                }
            } message: {
                Text("Вы уверены, что хотите удалить этот актив?")
            }
        }
        .onChange(of: typeSelection) { newValue in
            if case .newType = newValue {
                isShowingNewTypeAlert = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .alert("Новый тип", isPresented: $isShowingNewTypeAlert) {
            TextField("Название типа", text: $newTypeName)
            Button("Сохранить") {
                let newType = AssetType(name: newTypeName)
                modelContext.insert(newType)
                try? modelContext.save()
                typeSelection = .existing(newType)
                newTypeName = ""
            }
            Button("Отмена", role: .cancel) {
                typeSelection = .none
            }
        } message: {
            Text("Введите название для нового типа")
        }
    }

    private func deleteAsset() {
        guard let asset = draftAsset else { return }
        modelContext.delete(asset)
        try? modelContext.save()
        dismiss()
    }

    private func saveAndDismiss() {
        let finalType: AssetType? = {
            switch typeSelection {
            case .none:           return nil
            case .existing(let t): return t
            case .newType:        return nil
            }
        }()
        onSave(name, price, finalType)
        dismiss()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Серый кружок вместо диаграммы
            Circle()
                .stroke(Color.gray.opacity(0.4), lineWidth: 20)
                .frame(width: 180, height: 180)
                .overlay(
                    Text("0,00 ₽")
                        .font(.title2).bold()
                        .foregroundColor(.gray)
                )

            // Главный текст
            Text("У вас пока нет финансовых активов")
                .font(.headline)
                .foregroundColor(.primary)

            // Подсказка
            Text("Нажмите «+», чтобы добавить первый финансовый актив 📈 и следить за своим портфелем 💼")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

enum TypeSelection: Hashable {
    case none
    case existing(AssetType)
    case newType
}
