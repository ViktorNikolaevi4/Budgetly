import CloudKit
import Observation
import SwiftData

@Observable
final class CloudKitService {
    var displayName: String?
    var iCloudAvailable = false

    init() {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase

        // 1) проверяем статус iCloud
        container.accountStatus { status, _ in
            DispatchQueue.main.async {
                self.iCloudAvailable = (status == .available)
            }
            guard status == .available else { return }

            // 2) берём recordName текущего юзера
            container.fetchUserRecordID { recordID, _ in
                guard let rid = recordID else { return }
                let profileID = CKRecord.ID(recordName: "Profile-\(rid.recordName)")

                // 3) пытаемся загрузить существующий профиль
                privateDB.fetch(withRecordID: profileID) { record, error in
                    if let record,
                       let name = record["displayName"] as? String {
                        DispatchQueue.main.async {
                            self.displayName = name
                        }
                    } else {
                        // 4) если нет — заводим пустой профиль
                        let newRec = CKRecord(recordType: "Profile", recordID: profileID)
                        newRec["displayName"] = "" as NSString
                        privateDB.save(newRec) { _, _ in }
                    }
                }
            }
        }
    }

    func updateDisplayName(_ newName: String) {
        let container = CKContainer.default()
        container.fetchUserRecordID { recordID, _ in
            guard let rid = recordID else { return }
            let profileID = CKRecord.ID(recordName: "Profile-\(rid.recordName)")
            let privateDB = container.privateCloudDatabase

            privateDB.fetch(withRecordID: profileID) { record, _ in
                guard let record = record else { return }
                record["displayName"] = newName as NSString
                privateDB.save(record) { _, _ in
                    DispatchQueue.main.async {
                        self.displayName = newName
                    }
                }
            }
        }
    }
}
extension CloudKitService {
    func clearCloudKitData(completion: @escaping (Result<Void, Error>) -> Void) {
        let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
        let databases = [container.privateCloudDatabase, container.sharedCloudDatabase]
        let group = DispatchGroup()
        var deletionError: Error?

        for database in databases {
            // Получаем все зоны в базе
            group.enter()
            database.fetchAllRecordZones { zones, error in
                if let error = error {
                    deletionError = error
                    group.leave()
                    return
                }

                guard let zones = zones else {
                    group.leave()
                    return
                }

                // Удаляем каждую зону
                let zoneGroup = DispatchGroup()
                for zone in zones {
                    zoneGroup.enter()
                    database.delete(withRecordZoneID: zone.zoneID) { _, error in
                        if let error = error {
                            deletionError = error
                        }
                        zoneGroup.leave()
                    }
                }

                zoneGroup.notify(queue: .main) {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = deletionError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

enum CloudKitError: Error {
    case unknown
}

// MARK: — Функция очистки всех локальных данных SwiftData
func clearLocalData(in context: ModelContext) throws {
    let allAccounts     = try context.fetch(FetchDescriptor<Account>())
    let allTransactions = try context.fetch(FetchDescriptor<Transaction>())
    let allCategories   = try context.fetch(FetchDescriptor<Category>())
    let allPayments     = try context.fetch(FetchDescriptor<RegularPayment>())
    let allReminders    = try context.fetch(FetchDescriptor<Reminder>())
    let allAssets       = try context.fetch(FetchDescriptor<Asset>())
    let allAssetTypes   = try context.fetch(FetchDescriptor<AssetType>())

    // Удаляем по-отдельности
    allAccounts    .forEach { context.delete($0) }
    allTransactions.forEach { context.delete($0) }
    allCategories  .forEach { context.delete($0) }
    allPayments    .forEach { context.delete($0) }
    allReminders   .forEach { context.delete($0) }
    allAssets      .forEach { context.delete($0) }
    allAssetTypes  .forEach { context.delete($0) }

    try context.save()
}

