//import SwiftUI
//import SwiftData
//import CloudKit
//
//struct AccountDetailView: View {
//    @Environment(\.authService)    private var auth
//    @Environment(\.modelContext)   private var context
//    @Environment(\.dismiss)        private var dismiss
//
//    // Подхватываем все модели, чтобы при удалении чистить их
//    @Query private var accountsList:   [Account]
//    @Query private var transactions:   [Transaction]
//    @Query private var assets:         [Asset]
//
//    @State private var showDeleteAlert = false
//
//    var body: some View {
//        List {
//            Section {
//                HStack {
//                    Text("Имя / никнейм")
//                    Spacer()
//                    Text(auth.currentName ?? "-")
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            Section {
//                HStack {
//                    Text("E-mail")
//                    Spacer()
//                    Text(auth.currentEmail ?? "-")
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            Section {
//                NavigationLink("Изменить пароль") {
//                    ForgotPasswordView()
//                }
//            }
//
//            Section {
//                Button(role: .destructive) {
//                    showDeleteAlert = true
//                } label: {
//                    Text("Удалить аккаунт")
//                }
//                Text("Если вы решите удалить аккаунт, все ваши операции, счета и активы будут удалены без возможности восстановления.")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .padding(.top, 4)
//            }
//        }
//        .navigationTitle("Аккаунт и вход")
//        .navigationBarTitleDisplayMode(.inline)
//        .listStyle(.insetGrouped)
//        .alert("Вы действительно хотите удалить аккаунт?", isPresented: $showDeleteAlert) {
//            Button("Отмена", role: .cancel) { }
//            Button("Удалить", role: .destructive) {
//                deleteAccount()
//            }
//        } message: {
//            Text("Все ваши операции, счета и активы будут удалены без возможности восстановления.")
//        }
//    }
//
//    private func deleteAccount() {
//        // 0) вытащим recordName — тот же, что использовали при сохранении:
//        let recordName = auth.originalEmail ?? auth.currentEmail!
//        let recordID   = CKRecord.ID(recordName: recordName)
//        let db         = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
//                            .publicCloudDatabase
//
//        // 1) Асинхронно удаляем запись пользователя в CloudKit
//        db.delete(withRecordID: recordID) { deletedID, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("❌ Ошибка удаления аккаунта из CloudKit:", error)
//                } else {
//                    print("✅ Удалён CloudKit-рекорд:", deletedID?.recordName ?? "")
//                }
//            }
//        }
//
//        // 2) Логаут и очистка UserDefaults
//        auth.logout()
//
//        // 3) Удаляем все локальные данные SwiftData
//        for acc in accountsList   { context.delete(acc) }
//        for tx  in transactions   { context.delete(tx)  }
//        for asset in assets       { context.delete(asset) }
//
//        // 4) Возвращаемся назад
//        dismiss()
//    }
//
//}
