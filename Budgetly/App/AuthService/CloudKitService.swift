import CloudKit
import Observation
import UIKit

@MainActor
@Observable
final class CloudKitService {
    // Состояние
    var lastStatus: CKAccountStatus = .couldNotDetermine
    var lastError: Error?
    var isChecking = false

    /// Удобный алиас
    var iCloudAvailable: Bool { lastStatus == .available }

    /// 🔹 Имя пользователя из приватной БД (наш «профиль»)
    var displayName: String?     // ← добавили

    init() {
        Task { await refresh() }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    /// Проверить статус iCloud
    func refresh() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        do {
            lastStatus = try await CKContainer.default().accountStatus()
            lastError = nil

            if lastStatus == .available {
                await ensureProfileRecord()    // ← тянем/создаём профиль
            } else {
                displayName = nil
            }
        } catch {
            lastStatus = .couldNotDetermine
            lastError  = error
            displayName = nil
        }
    }

    func refreshNow() { Task { await refresh() } }

    // MARK: - Профиль iCloud в приватной БД
    private func ensureProfileRecord() async {
        let container = CKContainer.default()
        let db = container.privateCloudDatabase

        // Получаем userRecordID (через continuation, чтобы остаться на async/await)
        let rid: CKRecord.ID? = await withCheckedContinuation { cont in
            container.fetchUserRecordID { rid, _ in cont.resume(returning: rid) }
        }
        guard let rid else { return }

        let recID = CKRecord.ID(recordName: "Profile-\(rid.recordName)")

        // Пробуем найти запись
        let record: CKRecord? = await withCheckedContinuation { cont in
            db.fetch(withRecordID: recID) { record, _ in cont.resume(returning: record) }
        }

        if let record, let name = record["displayName"] as? String {
            displayName = name
            return
        }

        // Если записи нет — создаём пустую
        let newRec = CKRecord(recordType: "Profile", recordID: recID)
        newRec["displayName"] = "" as NSString
        db.save(newRec) { _, _ in }   // без ожидания ок
        displayName = nil
    }
}



// MARK: - CloudKit error helpers

extension CKError {
    /// Пытаемся вытащить человеческое сообщение об ошибке из userInfo.
    var serverMessage: String {
        let info = (self as NSError).userInfo
        return (info[NSLocalizedFailureReasonErrorKey] as? String)
            ?? (info[NSLocalizedDescriptionKey] as? String)
            ?? localizedDescription
    }

    /// Удобная проверка: схема recordType ещё не развернута (или недоступна).
    func isMissingRecordType(_ recordType: String) -> Bool {
        code == .unknownItem &&
        serverMessage.localizedCaseInsensitiveContains("record type: \(recordType)")
    }
}
