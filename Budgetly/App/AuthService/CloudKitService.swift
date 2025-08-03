import CloudKit
import Observation

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
