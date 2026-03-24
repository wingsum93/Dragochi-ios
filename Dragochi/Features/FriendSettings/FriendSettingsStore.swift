//
//  FriendSettingsStore.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import Foundation
import Combine

extension Notification.Name {
    static let friendsDidChange = Notification.Name("friendsDidChange")
}

@MainActor
final class FriendSettingsStore: ObservableObject {
    struct State: Equatable {
        var friends: [FriendEntity] = []
        var isLoading = false
        var errorMessage: String?
        var isReorderMode = false

        var isShowingEditDialog = false
        var editingFriendID: UUID?
        var editingName = ""
        var editingAvatarAssetName = FriendAvatarOptions.defaultAssetName
        var editingNote = ""
        var editValidationMessage: String?
        var editValidationMessageKey: String?

        var pendingDeleteFriend: FriendEntity?
        var isShowingDeleteDialog = false
    }

    enum Action {
        case onAppear
        case backTapped

        case addTapped
        case toggleReorderMode
        case moveFriends(IndexSet, Int)
        case editTapped(UUID)
        case updateEditingName(String)
        case updateEditingNote(String)
        case selectEditingAvatar(String)
        case saveEditingTapped
        case cancelEditingTapped

        case deleteTapped(UUID)
        case confirmDeleteTapped
        case cancelDeleteTapped
    }

    @Published private(set) var state = State()

    private let friendRepository: FriendRepository
    private let auditLogger: AuditLogging
    private let onClose: () -> Void

    init(dependencies: AppDependencies, onClose: @escaping () -> Void = {}) {
        self.friendRepository = dependencies.friendRepository
        self.auditLogger = dependencies.auditLogger
        self.onClose = onClose
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            loadFriends()
        case .backTapped:
            onClose()

        case .addTapped:
            presentAddDialog()
        case .toggleReorderMode:
            state.isReorderMode.toggle()
        case .moveFriends(let source, let destination):
            moveFriends(from: source, to: destination)
        case .editTapped(let friendID):
            presentEditDialog(friendID: friendID)
        case .updateEditingName(let name):
            state.editingName = name
            state.editValidationMessage = nil
        case .updateEditingNote(let note):
            state.editingNote = note
            state.editValidationMessage = nil
        case .selectEditingAvatar(let assetName):
            guard FriendAvatarOptions.isValid(assetName: assetName) else { return }
            state.editingAvatarAssetName = assetName
            state.editValidationMessage = nil
        case .saveEditingTapped:
            saveEditing()
        case .cancelEditingTapped:
            dismissEditDialog()

        case .deleteTapped(let friendID):
            requestDelete(friendID: friendID)
        case .confirmDeleteTapped:
            confirmDelete()
        case .cancelDeleteTapped:
            dismissDeleteDialog()
        }
    }

    var dialogTitleKey: String {
        state.editingFriendID == nil ? "title_add_friend" : "title_edit_friend"
    }

    private func loadFriends() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            state.friends = try fetchAndNormalizeActiveFriends()
            state.errorMessage = nil
            if state.friends.isEmpty {
                state.isReorderMode = false
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func presentAddDialog() {
        state.editingFriendID = nil
        state.editingName = ""
        state.editingAvatarAssetName = FriendAvatarOptions.defaultAssetName
        state.editingNote = ""
        state.editValidationMessage = nil
        state.editValidationMessageKey = nil
        state.isShowingEditDialog = true
    }

    private func presentEditDialog(friendID: UUID) {
        guard let friend = state.friends.first(where: { $0.id == friendID }) else { return }
        state.editingFriendID = friend.id
        state.editingName = friend.name
        state.editingAvatarAssetName = FriendAvatarOptions.isValid(assetName: friend.avatarAssetName)
            ? (friend.avatarAssetName ?? FriendAvatarOptions.defaultAssetName)
            : FriendAvatarOptions.defaultAssetName
        state.editingNote = friend.note ?? ""
        state.editValidationMessage = nil
        state.editValidationMessageKey = nil
        state.isShowingEditDialog = true
    }

    private func saveEditing() {
        let auditAction: AuditAction = state.editingFriendID == nil ? .friendAdded : .friendEdited
        let trimmedName = state.editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            state.editValidationMessage = nil
            state.editValidationMessageKey = "text_name_required"
            auditLogger.log(
                action: auditAction,
                outcome: .failure,
                metadata: [
                    "reason": "validation_name_required"
                ]
            )
            return
        }

        let normalizedName = trimmedName.lowercased()
        let hasDuplicate = state.friends.contains { friend in
            if let editingID = state.editingFriendID, friend.id == editingID {
                return false
            }
            return friend.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }
        guard !hasDuplicate else {
            state.editValidationMessage = nil
            state.editValidationMessageKey = "text_friend_name_already_exists"
            auditLogger.log(
                action: auditAction,
                outcome: .failure,
                metadata: [
                    "reason": "validation_duplicate_name"
                ]
            )
            return
        }

        let avatarAssetName = FriendAvatarOptions.isValid(assetName: state.editingAvatarAssetName)
            ? state.editingAvatarAssetName
            : FriendAvatarOptions.defaultAssetName
        let note = state.editingNote.isEmpty ? nil : state.editingNote

        do {
            let savedFriendID: UUID
            if let editingID = state.editingFriendID {
                guard let existing = state.friends.first(where: { $0.id == editingID }) else {
                    throw RepositoryError.notFound
                }
                var updated = existing
                updated.name = trimmedName
                updated.avatarAssetName = avatarAssetName
                updated.isActive = true
                updated.note = note
                let saved = try friendRepository.upsert(updated)
                savedFriendID = saved.id
            } else {
                let saved = try friendRepository.create(
                    name: trimmedName,
                    handle: nil,
                    avatarAssetName: avatarAssetName,
                    isActive: true,
                    order: nextOrderIndex(),
                    note: note
                )
                savedFriendID = saved.id
            }

            dismissEditDialog()
            state.friends = try fetchAndNormalizeActiveFriends()
            notifyFriendsDidChange()
            state.errorMessage = nil
            state.editValidationMessage = nil
            state.editValidationMessageKey = nil
            auditLogger.log(
                action: auditAction,
                outcome: .success,
                metadata: [
                    "friend_id": savedFriendID.uuidString,
                    "avatar_asset_name": avatarAssetName,
                    "has_note": AuditMetadata.bool(note != nil)
                ]
            )
        } catch {
            state.editValidationMessage = error.localizedDescription
            state.editValidationMessageKey = nil
            auditLogger.log(
                action: auditAction,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "avatar_asset_name": avatarAssetName,
                        "has_note": AuditMetadata.bool(note != nil)
                    ],
                    error: error
                )
            )
        }
    }

    private func dismissEditDialog() {
        state.isShowingEditDialog = false
        state.editValidationMessage = nil
        state.editValidationMessageKey = nil
    }

    private func requestDelete(friendID: UUID) {
        guard let friend = state.friends.first(where: { $0.id == friendID }) else { return }
        state.pendingDeleteFriend = friend
        state.isShowingDeleteDialog = true
        state.errorMessage = nil
    }

    private func confirmDelete() {
        guard let pending = state.pendingDeleteFriend else {
            dismissDeleteDialog()
            return
        }

        do {
            var updated = pending
            updated.isActive = false
            _ = try friendRepository.upsert(updated)
            dismissDeleteDialog()
            state.friends = try fetchAndNormalizeActiveFriends()
            if state.friends.isEmpty {
                state.isReorderMode = false
            }
            notifyFriendsDidChange()
            state.errorMessage = nil
            auditLogger.log(
                action: .friendDeleted,
                outcome: .success,
                metadata: [
                    "friend_id": pending.id.uuidString
                ]
            )
        } catch {
            state.errorMessage = error.localizedDescription
            dismissDeleteDialog()
            auditLogger.log(
                action: .friendDeleted,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "friend_id": pending.id.uuidString
                    ],
                    error: error
                )
            )
        }
    }

    private func dismissDeleteDialog() {
        state.pendingDeleteFriend = nil
        state.isShowingDeleteDialog = false
    }

    private func sortByDisplayOrder(_ friends: [FriendEntity]) -> [FriendEntity] {
        friends.sorted { lhs, rhs in
            if lhs.order != rhs.order {
                return lhs.order < rhs.order
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func fetchAndNormalizeActiveFriends() throws -> [FriendEntity] {
        let orderedFriends = sortByDisplayOrder(try friendRepository.fetchActive())
        return try normalizeOrdersIfNeeded(orderedFriends)
    }

    private func normalizeOrdersIfNeeded(_ friends: [FriendEntity]) throws -> [FriendEntity] {
        var normalized = friends
        var changedFriends: [FriendEntity] = []

        for index in normalized.indices {
            guard normalized[index].order != index else { continue }
            normalized[index].order = index
            changedFriends.append(normalized[index])
        }

        for friend in changedFriends {
            _ = try friendRepository.upsert(friend)
        }

        return normalized
    }

    private func nextOrderIndex() -> Int {
        (state.friends.map(\.order).max() ?? -1) + 1
    }

    private func moveFriends(from source: IndexSet, to destination: Int) {
        guard state.isReorderMode else { return }

        var reordered = applyMove(from: source, to: destination, in: state.friends)

        do {
            reordered = try normalizeOrdersIfNeeded(reordered)
            state.friends = reordered
            state.errorMessage = nil
            notifyFriendsDidChange()
            auditLogger.log(
                action: .friendReordered,
                outcome: .success,
                metadata: [
                    "moved_count": String(source.count),
                    "destination": String(destination),
                    "total_friends": String(reordered.count)
                ]
            )
        } catch {
            state.errorMessage = error.localizedDescription
            do {
                state.friends = try fetchAndNormalizeActiveFriends()
            } catch {
                state.errorMessage = error.localizedDescription
            }
            auditLogger.log(
                action: .friendReordered,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "moved_count": String(source.count),
                        "destination": String(destination),
                        "total_friends": String(state.friends.count)
                    ],
                    error: error
                )
            )
        }
    }

    private func applyMove(from source: IndexSet, to destination: Int, in friends: [FriendEntity]) -> [FriendEntity] {
        let moving = source.map { friends[$0] }
        var remaining = friends.enumerated().compactMap { index, friend in
            source.contains(index) ? nil : friend
        }
        let sourceBeforeDestinationCount = source.filter { $0 < destination }.count
        let adjustedDestination = max(0, min(destination - sourceBeforeDestinationCount, remaining.count))
        remaining.insert(contentsOf: moving, at: adjustedDestination)
        return remaining
    }

    private func notifyFriendsDidChange() {
        NotificationCenter.default.post(name: .friendsDidChange, object: nil)
    }
}
