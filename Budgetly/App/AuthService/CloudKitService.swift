import CloudKit
import UIKit
import Observation

@Observable
final class CloudKitService {
    var displayName: String?
    var iCloudAvailable = false
    var lastStatus: CKAccountStatus = .couldNotDetermine
    var lastError: Error?

    init() {
         refresh()
         // Опционально: обновлять статус при возвращении в приложение
         NotificationCenter.default.addObserver(
             forName: UIApplication.didBecomeActiveNotification,
             object: nil, queue: .main
         ) { [weak self] _ in
             self?.refresh()
         }
     }

     // NEW:
     func refresh() {
         let container = CKContainer.default()
         container.accountStatus { [weak self] status, error in
             DispatchQueue.main.async {
                 guard let self else { return }
                 self.lastStatus = status
                 self.lastError  = error
                 self.iCloudAvailable = (status == .available)

                 guard status == .available else { return }
                 self.loadProfile(from: container)
             }
         }
     }

    private func loadProfile(from container: CKContainer) {
        let db = container.privateCloudDatabase
        container.fetchUserRecordID { [weak self] rid, _ in
            guard
              let self = self,
              let rid = rid
            else { return }

            let recID = CKRecord.ID(recordName: "Profile-\(rid.recordName)")
            db.fetch(withRecordID: recID) { record, _ in
                if let record,
                   let name = record["displayName"] as? String {
                    DispatchQueue.main.async {
                        self.displayName = name
                    }
                } else {
                    let newRec = CKRecord(recordType: "Profile", recordID: recID)
                    newRec["displayName"] = "" as NSString
                    db.save(newRec) { _, _ in }
                }
            }
        }
    }

    func updateDisplayName(to newName: String) {
        let container = CKContainer.default()
        let db = container.privateCloudDatabase
        container.fetchUserRecordID { [weak self] rid, _ in
            guard
              let self = self,
              let rid = rid
            else { return }
            let recID = CKRecord.ID(recordName: "Profile-\(rid.recordName)")
            db.fetch(withRecordID: recID) { record, _ in
                guard let record = record else { return }
                record["displayName"] = newName as NSString
                db.save(record) { _, _ in
                    DispatchQueue.main.async {
                        self.displayName = newName
                    }
                }
            }
        }
    }

    /// Ручной форс-апдейт (опционально)
    func fetchChanges() {
      // можно вызвать CKFetchRecordZoneChangesOperation…
      // но с `.automatic` SwiftData синхронизирует сам
    }
}
