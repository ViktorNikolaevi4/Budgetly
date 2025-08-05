//import SwiftData
//import CloudKit
//
//enum CloudKitError: Error {
//  case unknown
//}
//
///// Удаляет все записи из локального SwiftData-контекста
//func clearLocalData(in context: ModelContext) throws {
//    let allAccounts     = try context.fetch(FetchDescriptor<Account>())
//    let allTransactions = try context.fetch(FetchDescriptor<Transaction>())
//    let allCategories   = try context.fetch(FetchDescriptor<Category>())
//    let allPayments     = try context.fetch(FetchDescriptor<RegularPayment>())
//    let allReminders    = try context.fetch(FetchDescriptor<Reminder>())
//    let allAssets       = try context.fetch(FetchDescriptor<Asset>())
//    let allAssetTypes   = try context.fetch(FetchDescriptor<AssetType>())
//
//    // удаляем по одной сущности в контексте
//    allAccounts    .forEach { context.delete($0) }
//    allTransactions.forEach { context.delete($0) }
//    allCategories  .forEach { context.delete($0) }
//    allPayments    .forEach { context.delete($0) }
//    allReminders   .forEach { context.delete($0) }
//    allAssets      .forEach { context.delete($0) }
//    allAssetTypes  .forEach { context.delete($0) }
//
//    try context.save()
//}
//
///// Удаляет все приватные зоны из вашего iCloud-контейнера
//func clearCloudKitData(completion: @escaping (Result<Void, Error>) -> Void) {
//    let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
//    let databases = [container.privateCloudDatabase, container.sharedCloudDatabase]
//    let group = DispatchGroup()
//    var deletionError: Error?
//
//    for db in databases {
//        group.enter()
//        db.fetchAllRecordZones { zones, err in
//            if let err = err {
//                deletionError = err
//                group.leave()
//                return
//            }
//            guard let zones = zones else {
//                group.leave()
//                return
//            }
//            let zoneGroup = DispatchGroup()
//            for zone in zones {
//                zoneGroup.enter()
//                db.delete(withRecordZoneID: zone.zoneID) { _, err in
//                    if let err = err { deletionError = err }
//                    zoneGroup.leave()
//                }
//            }
//            zoneGroup.notify(queue: .main) { group.leave() }
//        }
//    }
//
//    group.notify(queue: .main) {
//        if let err = deletionError {
//            completion(.failure(err))
//        } else {
//            completion(.success(()))
//        }
//    }
//}

