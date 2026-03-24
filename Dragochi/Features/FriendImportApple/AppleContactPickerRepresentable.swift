//
//  AppleContactPickerRepresentable.swift
//  Dragochi
//
//  Created by Codex on 21/3/2026.
//

import Contacts
import ContactsUI
import SwiftUI

struct ImportedAppleContact: Identifiable, Equatable, Hashable {
    let id: String
    let fullName: String
    let email: String?
    let phone: String?
}

struct AppleContactPickerRepresentable: UIViewControllerRepresentable {
    let onContactsSelected: ([ImportedAppleContact]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        private let parent: AppleContactPickerRepresentable

        init(parent: AppleContactPickerRepresentable) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onContactsSelected([mapContact(contact)])
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.onContactsSelected(contacts.map(mapContact))
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onCancel()
        }

        private func mapContact(_ contact: CNContact) -> ImportedAppleContact {
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                ?? [contact.givenName, contact.middleName, contact.familyName]
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let email = contact.emailAddresses.first?.value as String?
            let phone = contact.phoneNumbers.first?.value.stringValue

            return ImportedAppleContact(
                id: contact.identifier,
                fullName: fullName,
                email: email,
                phone: phone
            )
        }
    }
}
