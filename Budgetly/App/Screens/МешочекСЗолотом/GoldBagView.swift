
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
    @Query private var assets: [Asset]
    @Query private var assetTypes: [AssetType]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Для закрытия экрана

    @State private var isAddAssetPresented = false
    @State private var selectedAsset: Asset? = nil

    private var groupedAssets: [(name: String, totalPrice: Double, type: AssetType?, assets: [Asset])] {
        var assetDict: [String: (totalPrice: Double, type: AssetType?, assets: [Asset])] = [:]

        for asset in assets {
            let key = "\(asset.name)_\(asset.assetType?.name ?? "Без типа")"

            if assetDict[key] != nil {
                assetDict[key]?.totalPrice += asset.price
                assetDict[key]?.assets.append(asset)
            } else {
                assetDict[key] = (totalPrice: asset.price, type: asset.assetType, assets: [asset])
            }
        }

        return assetDict.map { (name: $0.key.components(separatedBy: "_")[0],
                                totalPrice: $0.value.totalPrice,
                                type: $0.value.type,
                                assets: $0.value.assets) }
            .sorted { $0.name < $1.name }
    }

    private var totalPrice: Double {
        assets.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedAssets, id: \.name) { assetGroup in
                    Button {
                        if let firstAsset = assetGroup.assets.first {
                            selectedAsset = firstAsset // Открываем редактирование
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(assetGroup.name)
                                    .font(.headline)
                                    .foregroundColor(.appPurple)
                                Text(assetGroup.type?.name ?? "Нет типа")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(assetGroup.totalPrice, specifier: "%.2f") ₽")
                                .font(.headline)
                                .foregroundColor(.appPurple)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAssets)
            }
            .navigationTitle("Мои активы")
            .toolbar {
                // Кнопка закрытия в левом верхнем углу
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        dismiss() // Закрываем экран
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.title2)
//                            .foregroundColor(.red)
//                    }
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Text("\(totalPrice, specifier: "%.2f") ₽")
                            .foregroundColor(.appPurple)
                            .font(.headline)

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
            // Когда экран появляется, добавляем дефолтные типы (если их ещё нет)
            .onAppear {
                createDefaultAssetTypesIfNeeded()
            }
            .sheet(isPresented: $isAddAssetPresented) {
                AddOrEditAssetView(
                    draftAsset: nil,
                    assetTypes: assetTypes,
                    onSave: { newName, newPrice, chosenType in
                        let newAsset = Asset(name: newName, price: newPrice, assetType: chosenType)
                        modelContext.insert(newAsset)
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $selectedAsset) { asset in
                AddOrEditAssetView(
                    draftAsset: asset,
                    assetTypes: assetTypes,
                    onSave: { newName, newPrice, chosenType in
                        asset.name = newName
                        asset.price = newPrice
                        asset.assetType = chosenType
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func deleteAssets(at offsets: IndexSet) {
        for index in offsets {
            let asset = assets[index]
            modelContext.delete(asset)
        }
        try? modelContext.save()
    }
    private func createDefaultAssetTypesIfNeeded() {
        // Список «дефолтных» названий типов
        let defaultNames = ["Акции", "Облигации", "Недвижимость"]

        // Превращаем все имеющиеся типы в множество их названий
        let existingNames = Set(assetTypes.map { $0.name })

        // Для каждого «дефолтного» названия проверяем, нет ли его уже
        for name in defaultNames {
            if !existingNames.contains(name) {
                let newType = AssetType(name: name)
                modelContext.insert(newType)
            }
        }

        // Сохраняем изменения, если что-то добавили
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении дефолтных типов: \(error.localizedDescription)")
        }
    }

}


// View для добавления/редактирования актива
struct AddOrEditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let draftAsset: Asset?
    let assetTypes: [AssetType]
    let onSave: (String, Double, AssetType?) -> Void

    @State private var name: String
    @State private var price: Double

    /// Текущее «логическое» состояние выбора типа (none / existing / newType)
    @State private var typeSelection: TypeSelection = .none
    /// Нужно ли показывать алерт для ввода названия нового типа
    @State private var isShowingNewTypeAlert = false
    /// Название, которое пользователь введёт в алерте
    @State private var newTypeName = ""

 //   @State private var reductionAmount: Double = 0.0 // Для частичной продажи

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

        // Если редактируем готовый Asset и у него есть тип:
        if let existingType = draftAsset?.assetType {
            _typeSelection = State(initialValue: .existing(existingType))
        } else {
            // Иначе считаем, что пока выбрано "none"
            _typeSelection = State(initialValue: .none)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название актива") {
                    TextField("Введите название", text: $name)
                }

                Section("Тип") {
                    Picker("Выберите тип", selection: $typeSelection) {
                        // Пункт "Без типа"
                        Text("Без типа").tag(TypeSelection.none)

                        // Существующие типы
                        ForEach(assetTypes, id: \.id) { type in
                            Text(type.name).tag(TypeSelection.existing(type))
                        }

                        // Пункт "Новый тип…"
                        Text("Новый тип…").tag(TypeSelection.newType)
                    }
                    .pickerStyle(.menu)
                    .tint(.appPurple)
                    .onChange(of: typeSelection) { newValue in
                        // Если пользователь выбрал "Новый тип…",
                        // сразу показываем алерт с TextField
                        if case .newType = newValue {
                            isShowingNewTypeAlert = true
                        }
                    }
                }

                Section("Переоценка стоимости (₽)") {
                    TextField("Введите цену", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                }

                // Блок для частичной продажи, только если у нас реальный asset
//                if draftAsset != nil {
//                    Section("Продажа части актива") {
//                        TextField("Сумма для продажи", value: $reductionAmount, format: .number)
//                            .keyboardType(.decimalPad)
//                        Button("Продать") {
//                            sellPartOfAsset()
//                        }
//                        .disabled(reductionAmount <= 0 || reductionAmount > price)
//                    }
//                }
            }
            .navigationTitle(draftAsset == nil ? "Новый актив" : "Редактировать актив")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // Определяем, какой тип в итоге будет (nil, existing, или только что созданный)
                        let finalType: AssetType? = {
                            switch typeSelection {
                            case .none:
                                return nil
                            case .existing(let t):
                                return t
                            case .newType:
                                // Вдруг пользователь зашёл в алерт, но отменил; тогда здесь оставляем nil
                                // (или можно хранить в отдельном стейте, если успел сохранить)
                                return nil
                            }
                        }()

                        onSave(name, price, finalType)
                        dismiss()
                    } label: {
                        Text("Сохранить")
                            .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? .gray.opacity(0.3) : .appPurple)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }.foregroundStyle(.appPurple)
                }
            }
            // Тот самый alert iOS16+ с TextField
            .alert("Новый тип", isPresented: $isShowingNewTypeAlert, actions: {
                TextField("Введите название типа", text: $newTypeName)
                Button("Сохранить") {
                    guard !newTypeName.isEmpty else {
                        // Если ничего не ввели — просто закрываем
                        typeSelection = .none
                        return
                    }
                    // Создаём AssetType в контексте
                    let newType = AssetType(name: newTypeName)
                    modelContext.insert(newType)
                    try? modelContext.save()

                    // Сбрасываем поле ввода
                    newTypeName = ""
                    // Устанавливаем выбранный тип
                    typeSelection = .existing(newType)
                }
                Button("Отмена", role: .cancel) {
                    // Если нажали "Отмена", возвращаемся к предыдущему состоянию
                    // (по умолчанию пусть будет .none)
                    typeSelection = .none
                }
            }, message: {
                Text("Введите название для нового типа актива")
            })
        }
    }

//    private func sellPartOfAsset() {
//        guard let draftAsset = draftAsset,
//              reductionAmount > 0,
//              reductionAmount <= price else { return }
//
//        draftAsset.price -= reductionAmount
//        reductionAmount = 0
//        try? modelContext.save()
//    }
}

// Перечисление для выбора типа внутри Picker
enum TypeSelection: Hashable {
    case none                // «Без типа»
    case existing(AssetType) // Пользователь выбрал существующий тип
    case newType                 // «Новый тип...»
}
