import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool  // <-- теперь управляем извне
    let subject: String
    let recipient: String
    let messageBody: String
    let senderEmail: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerView

        init(parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) {
                // как только контроллер закрылся, скрываем SwiftUI sheet
                self.parent.isPresented = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([recipient])
        mail.setSubject(subject)
        mail.setMessageBody("От: \(senderEmail)\n\n\(messageBody)", isHTML: false)
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

