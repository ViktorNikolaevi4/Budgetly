import SwiftUI
import SwiftData
import Charts

@Model
class AssetType {
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
    @Relationship
    var assetType: AssetType?

    init(name: String, price: Double, assetType: AssetType? = nil) {
        self.id = UUID()
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
        NavigationStack {
            VStack(alignment: .leading) {
                Chart(assetGroups) { item in
                    SectorMark(
                        angle: .value("Сумма", item.sum),
                        innerRadius: .ratio(0.75),
                        outerRadius: .ratio(1.0),
                        angularInset: 1.0
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.color)
                }
                .chartLegend(.hidden)
                .frame(width: 180, height: 180)
                .overlay(
                    VStack {
                        Text("\(totalPrice.toShortStringWithSuffix()) ₽")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.black)
                    }
                )
                .padding()
            }

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
                            Button {
                                selectedAsset = asset
                            } label: {
                                HStack {
                                    Text(asset.name)
                                    Spacer()
                                    Text("\(asset.price, specifier: "%.2f") ₽")
                                }
                                .foregroundColor(.black)
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(asset: asset)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                          HStack(spacing: 8) {
                            // точка-цвет
                            Circle()
                              .fill(group.color)
                              .frame(width: 10, height: 10)

                            // название
                            Text(group.type?.name ?? "Без типа")
                              .font(.title3).bold()
                              .foregroundColor(.primary)

                            Spacer()

                            // сумма · разделитель · процент
                            HStack(spacing: 6) {
                              Text("\(group.sum.toShortStringWithSuffix()) ₽")
                              // маленький кружочек-разделитель
                              Circle()
                                .frame(width: 4, height: 4)
                                .foregroundColor(.gray.opacity(0.6))
                              Text(String(format: "%.1f%%", group.sum / totalPrice * 100))
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                          }
                          .padding(.vertical, 4)
                        }
                        .tint(.black)
                      }
                    }
            .navigationTitle("Мои активы")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
             //       HStack(spacing: 16) {
//                        Text("Мои активы")
//                            .font(.title2)
//                            .bold()
//                            .foregroundColor(.black)
//                        Spacer()
//                        Text("\(totalPrice, specifier: "%.2f") ₽")
//                            .foregroundColor(.black)
//                            .font(.title3).bold()
                        Button {
                            isAddAssetPresented = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundStyle(.appPurple)
                        }
                  //  }
                }
            }
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
                        do {
                            try modelContext.save()
                        } catch {
                            print("Ошибка сохранения: \(error.localizedDescription)")
                        }
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
                        do {
                            try modelContext.save()
                        } catch {
                            print("Ошибка сохранения: \(error.localizedDescription)")
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func delete(asset: Asset) {
        modelContext.delete(asset)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении: \(error.localizedDescription)")
        }
    }

    private func createDefaultAssetTypesIfNeeded() {
        let defaultNames = ["Акции", "Облигации", "Недвижимость"]
        let existingNames = Set(assetTypes.map { $0.name })

        for name in defaultNames {
            if !existingNames.contains(name) {
                let newType = AssetType(name: name)
                modelContext.insert(newType)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении дефолтных типов: \(error.localizedDescription)")
        }
    }
}

// AddOrEditAssetView остаётся без изменений
struct AddOrEditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let draftAsset: Asset?
    let assetTypes: [AssetType]
    let onSave: (String, Double, AssetType?) -> Void

    @State private var name: String
    @State private var price: Double
    @State private var typeSelection: TypeSelection = .none
    @State private var isShowingNewTypeAlert = false
    @State private var newTypeName = ""

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
             // 1) Общий серый фон во всю шторку
             Color(.systemGray6)
                 .ignoresSafeArea()

             VStack(spacing: 16) {
                 // ваша ручка и заголовок
                 Capsule()
                     .frame(width: 36, height: 5)
                     .foregroundColor(.gray.opacity(0.3))
                     .padding(.top, 8)

                 HStack {
                     Text(draftAsset == nil ? "Новый актив" : "Редактировать актив")
                         .font(.title2).bold()
                     Spacer()
                     Button { dismiss() } label: {
                         Image(systemName: "xmark")
                             .font(.system(size: 18, weight: .semibold))
                             .foregroundColor(.gray)
                     }
                 }
                 .padding(.horizontal)

                 // 2) Сам контент
                 Form {
                     Section {
                         TextField("Введите название", text: $name)
                     }
                     Section {
                         Picker("Выберите тип", selection: $typeSelection) {
                             Text("Без типа").tag(TypeSelection.none)
                             ForEach(assetTypes, id: \.id) { t in
                                 Text(t.name).tag(TypeSelection.existing(t))
                             }
                             Text("Новый тип…").tag(TypeSelection.newType)
                         }
                         .pickerStyle(.menu)
                         .onChange(of: typeSelection) { new in
                             if case .newType = new {
                                 isShowingNewTypeAlert = true
                             }
                         }
                     }
                     Section {
                         HStack {
                             Text("Стоимость")
                             Spacer()
                             TextField("0", value: $price, format: .number)
                                 .keyboardType(.decimalPad)
                                 .multilineTextAlignment(.trailing)
                                 .frame(maxWidth: 100)
                         }
                     }
                 }
                 // 3) Отключаем белый фон Form и закрашиваем его тем же серым
                 .scrollContentBackground(.hidden)
                 .background(Color(.systemGray6))

                 // 4) Кнопка снизу
                 Button(action: saveAndDismiss) {
                     Text(draftAsset == nil ? "Добавить" : "Сохранить")
                         .frame(maxWidth: .infinity, minHeight: 50)
                         .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.gray.opacity(0.5)
                                     : Color.appPurple)
                         .foregroundColor(.white)
                         .cornerRadius(16)
                         .padding()
                 }
                 .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
             }
         }
         // если вы вызываете .sheet, тут можно добавить:
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

    private func saveAndDismiss() {
        // определяем, какой тип передавать в колбэк
        let finalType: AssetType? = {
            switch typeSelection {
            case .none: return nil
            case .existing(let t): return t
            case .newType:    return nil
            }
        }()
        onSave(name, price, finalType)
        dismiss()
    }
}


enum TypeSelection: Hashable {
    case none
    case existing(AssetType)
    case newType
}
