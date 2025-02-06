

import SwiftUI
import SwiftData

@Model
class AssetType {
    // Поле для уникальной идентификации (необязательно, SwiftData сам создаст id).
    // Но для наглядности можно использовать UUID.
    // Или вы можете его не указывать вовсе, тогда SwiftData сделает ID автоматически.
    var id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
class Asset {
    var id: UUID
    var name: String
    var price: Double

    // Ссылка на AssetType (возможно nil, если пользователь не выбрал тип)
    // Чтобы была "один-к-многим" связь: один тип может быть у многих активов.
    @Relationship
    var assetType: AssetType?

    init(name: String, price: Double, assetType: AssetType? = nil) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.assetType = assetType
    }
}

struct GoldBagView: View {
    // Подтягиваем все активы
    @Query private var assets: [Asset]
    // Подтягиваем все доступные типы активов
    @Query private var assetTypes: [AssetType]

    // Для удаления/добавления нужен контекст
    @Environment(\.modelContext) private var modelContext

    @State private var isAddAssetPresented = false
    @State private var selectedAsset: Asset? = nil

    private var totalPrice: Double {
        assets.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(assets) { asset in
                    Button {
                        selectedAsset = asset // Редактируем существующий
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.name)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text(asset.assetType?.name ?? "Нет типа")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(asset.price, specifier: "%.2f") ₽")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAssets)
            }
            .navigationTitle("Мои активы")
            .toolbar {
                // Кнопка добавления нового актива
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Отобразим общую сумму
                        Text("\(totalPrice, specifier: "%.2f") ₽")
                            .foregroundColor(.blue)
                            .font(.headline)

                        Button {
                            isAddAssetPresented = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddAssetPresented) {
                AddOrEditAssetView(
                    // При добавлении создаём «пустой» объект
                    draftAsset: nil,
                    assetTypes: assetTypes,
                    onSave: { newName, newPrice, chosenType in
                        // Создаём новый объект в SwiftData
                        let newAsset = Asset(name: newName, price: newPrice, assetType: chosenType)
                        modelContext.insert(newAsset)
                        try? modelContext.save()
                    }
                )
            }
            // Редактирование существующего
            .sheet(item: $selectedAsset) { asset in
                AddOrEditAssetView(
                    draftAsset: asset,
                    assetTypes: assetTypes,
                    onSave: { newName, newPrice, chosenType in
                        // Модифицируем существующий объект
                        asset.name = newName
                        asset.price = newPrice
                        asset.assetType = chosenType
                        try? modelContext.save()
                    }
                )
            }
        }
    }

    private func deleteAssets(at offsets: IndexSet) {
        // Удаляем из SwiftData
        for index in offsets {
            let asset = assets[index]
            modelContext.delete(asset)
        }
        try? modelContext.save()
    }
}

// View для добавления/редактирования актива
struct AddOrEditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Если nil, значит создаём новый Asset, иначе редактируем существующий
    let draftAsset: Asset?

    // Список типов, пришедших из @Query
    // Можно было бы тоже читать их напрямую, но удобнее передать извне.
    let assetTypes: [AssetType]

    // Колбэк для сохранения (создания/редактирования)
    let onSave: (String, Double, AssetType?) -> Void

    // Локальные поля формы
    @State private var name: String
    @State private var price: Double
    @State private var chosenType: AssetType?

    // Добавление нового типа
    @State private var showNewTypeAlert = false
    @State private var newTypeName = ""

    init(
        draftAsset: Asset?,
        assetTypes: [AssetType],
        onSave: @escaping (String, Double, AssetType?) -> Void
    ) {
        self.draftAsset = draftAsset
        self.assetTypes = assetTypes
        self.onSave = onSave

        // Инициализируем State начальными значениями
        _name = State(initialValue: draftAsset?.name ?? "")
        _price = State(initialValue: draftAsset?.price ?? 0.0)
        _chosenType = State(initialValue: draftAsset?.assetType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название актива") {
                    TextField("Введите название", text: $name)
                }
                Section("Тип") {
                    Picker("Выберите тип", selection: $chosenType) {
                        Text("Без типа").tag(AssetType?.none)
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type.name).tag(type as AssetType?)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Добавить новый тип") {
                        showNewTypeAlert = true
                    }
                }
                Section("Цена (₽)") {
                    TextField("Введите цену", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(draftAsset == nil ? "Новый актив" : "Редактировать актив")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(name, price, chosenType)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Новый тип", isPresented: $showNewTypeAlert) {
                TextField("Например, \"Искусство\"", text: $newTypeName)
                Button("Добавить") {
                    addNewType()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Введите название нового типа актива")
            }
        }
    }

    private func addNewType() {
        let trimmed = newTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Создаём новый тип и сохраняем в базу
        let newType = AssetType(name: trimmed)
        modelContext.insert(newType)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка сохранения нового типа: \(error)")
        }

        // Обновляем локальную переменную, чтобы выбрать только что добавленный тип
        chosenType = newType
        newTypeName = ""
    }
}


