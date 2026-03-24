//
//  ReportIssueMailComposeView.swift
//  Dragochi
//
//  Created by Codex on 23/3/2026.
//

import MessageUI
import SwiftUI

struct ReportIssueMailComposeView: UIViewControllerRepresentable {
    let draft: IssueReportDraft
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([draft.recipient])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)

        if
            let attachmentURL = draft.attachmentURL,
            let data = try? Data(contentsOf: attachmentURL)
        {
            controller.addAttachmentData(
                data,
                mimeType: draft.attachmentMimeType,
                fileName: draft.attachmentFileName
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            _ = result
            _ = error
            controller.dismiss(animated: true)
            onFinish()
        }
    }
}
