import CloudKit
import Observation
import UIKit

@MainActor
@Observable
final class CloudKitService {
    // базовые состояния
    var lastStatus: CKAccountStatus = .couldNotDetermine
    var lastError: Error?
    var isChecking = false

    // ✅ алиас под старый API: то, что ждут экраны
    var iCloudAvailable: Bool { lastStatus == .available }

    // ✅ если экраны показывают имя профиля
    var displayName: String?

    init() {
        // лёгкий старт, без UI
        Task { await refresh() }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func refresh() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            let status = try await CKContainer.default().accountStatus()
            lastStatus = status
            lastError = nil
        } catch {
            lastStatus = .couldNotDetermine
            lastError  = error
        }
    }
    
    func refreshNow() { Task { await refresh() } }
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
