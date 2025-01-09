import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    var subject: String
    var recipient: String
    var messageBody: String
    var senderEmail: String

    @Environment(\.dismiss) var dismiss

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerView

        init(_ parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
