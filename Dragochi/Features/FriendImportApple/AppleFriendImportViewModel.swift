//
//  AppleFriendImportViewModel.swift
//  Dragochi
//
//  Created by Codex on 21/3/2026.
//

import Combine
import Contacts
import Foundation

@MainActor
final class AppleFriendImportViewModel: ObservableObject {
    struct State: Equatable {
        var selectedContacts: [ImportedAppleContact] = []
        var isShowingPicker = false
        var isShowingDuplicateAlert = false
        var duplicateCount = 0
        var pendingContactsForImport: [ImportedAppleContact] = []
        var isShowingFeedbackAlert = false
        var feedbackMessage: String?
        var feedbackMessageKey: String?
        var isImporting = false
    }

    enum Action {
        case importTapped
        case reselectTapped
        case contactsSelected([ImportedAppleContact])
        case contactSelectionCancelled
        case confirmImportTapped
        case confirmDuplicateImportTapped
        case cancelDuplicateImportTapped
        case dismissFeedbackAlert
        case closeTapped
    }

    @Published private(set) var state = State()

    private let friendRepository: FriendRepository
    private let auditLogger: AuditLogging
    private let onClose: () -> Void

    init(
        friendRepository: FriendRepository,
        auditLogger: AuditLogging,
        onClose: @escaping () -> Void = {}
    ) {
        self.friendRepository = friendRepository
        self.auditLogger = auditLogger
        self.onClose = onClose
    }

    func send(_ action: Action) {
        switch action {
        case .importTapped, .reselectTapped:
            presentPickerIfPossible()
        case .contactsSelected(let contacts):
            applySelectedContacts(contacts)
        case .contactSelectionCancelled:
            state.isShowingPicker = false
        case .confirmImportTapped:
            handleConfirmTapped()
        case .confirmDuplicateImportTapped:
            let contactsToImport = state.pendingContactsForImport
            let duplicateCount = state.duplicateCount
            state.isShowingDuplicateAlert = false
            state.pendingContactsForImport = []
            auditLogger.log(
                action: .appleDuplicateImportConfirmed,
                outcome: .success,
                metadata: [
                    "duplicate_count": String(duplicateCount),
                    "pending_import_count": String(contactsToImport.count)
                ]
            )
            importContacts(contactsToImport)
        case .cancelDuplicateImportTapped:
            state.isShowingDuplicateAlert = false
            state.pendingContactsForImport = []
        case .dismissFeedbackAlert:
            state.isShowingFeedbackAlert = false
            state.feedbackMessage = nil
            state.feedbackMessageKey = nil
        case .closeTapped:
            onClose()
        }
    }

    private func presentPickerIfPossible() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authorizationStatus {
        case .authorized, .notDetermined:
            state.isShowingPicker = true
        case .denied, .restricted:
            state.feedbackMessage = nil
            state.feedbackMessageKey = "text_contacts_permission_required"
            state.isShowingFeedbackAlert = true
        @unknown default:
            state.feedbackMessage = nil
            state.feedbackMessageKey = "text_contacts_permission_required"
            state.isShowingFeedbackAlert = true
        }
    }

    private func applySelectedContacts(_ contacts: [ImportedAppleContact]) {
        state.isShowingPicker = false
        state.isShowingDuplicateAlert = false
        state.pendingContactsForImport = []

        var seenIDs: Set<String> = []
        state.selectedContacts = contacts.filter { contact in
            seenIDs.insert(contact.id).inserted
        }
    }

    private func handleConfirmTapped() {
        let contactsToImport = state.selectedContacts.filter {
            !$0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !contactsToImport.isEmpty else {
            state.feedbackMessage = nil
            state.feedbackMessageKey = "text_import_no_valid_contacts"
            state.isShowingFeedbackAlert = true
            auditLogger.log(
                action: .appleContactsImported,
                outcome: .failure,
                metadata: [
                    "reason": "no_valid_contacts"
                ]
            )
            return
        }

        do {
            let existingNames = Set(
                try friendRepository.fetchActive().map {
                    normalizeName($0.name)
                }
            )

            let duplicateCount = contactsToImport.reduce(into: 0) { count, contact in
                if existingNames.contains(normalizeName(contact.fullName)) {
                    count += 1
                }
            }

            if duplicateCount > 0 {
                state.duplicateCount = duplicateCount
                state.pendingContactsForImport = contactsToImport
                state.isShowingDuplicateAlert = true
                return
            }

            importContacts(contactsToImport)
        } catch {
            state.feedbackMessage = error.localizedDescription
            state.feedbackMessageKey = nil
            state.isShowingFeedbackAlert = true
            auditLogger.log(
                action: .appleContactsImported,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "requested_import_count": String(contactsToImport.count)
                    ],
                    error: error
                )
            )
        }
    }

    private func importContacts(_ contacts: [ImportedAppleContact]) {
        guard !contacts.isEmpty else { return }

        state.isImporting = true
        defer { state.isImporting = false }

        do {
            let existingFriends = try friendRepository.fetchActive()
            var nextOrder = (existingFriends.map(\.order).max() ?? -1) + 1
            var importedCount = 0

            for contact in contacts {
                let trimmedName = contact.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { continue }

                _ = try friendRepository.create(
                    name: trimmedName,
                    handle: nil,
                    avatarAssetName: nil,
                    isActive: true,
                    order: nextOrder,
                    note: nil
                )
                importedCount += 1
                nextOrder += 1
            }

            guard importedCount > 0 else {
                state.feedbackMessage = nil
                state.feedbackMessageKey = "text_import_no_valid_contacts"
                state.isShowingFeedbackAlert = true
                auditLogger.log(
                    action: .appleContactsImported,
                    outcome: .failure,
                    metadata: [
                        "reason": "no_valid_contacts",
                        "requested_import_count": String(contacts.count)
                    ]
                )
                return
            }

            NotificationCenter.default.post(name: .friendsDidChange, object: nil)
            auditLogger.log(
                action: .appleContactsImported,
                outcome: .success,
                metadata: [
                    "requested_import_count": String(contacts.count),
                    "imported_count": String(importedCount)
                ]
            )
            onClose()
        } catch {
            state.feedbackMessage = error.localizedDescription
            state.feedbackMessageKey = nil
            state.isShowingFeedbackAlert = true
            auditLogger.log(
                action: .appleContactsImported,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "requested_import_count": String(contacts.count)
                    ],
                    error: error
                )
            )
        }
    }

    private func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
}
