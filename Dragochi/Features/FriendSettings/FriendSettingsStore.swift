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

        var isShowingEditDialog = false
        var editingFriendID: UUID?
        var editingName = ""
        var editingAvatarAssetName = FriendAvatarOptions.defaultAssetName
        var editValidationMessage: String?

        var pendingDeleteFriend: FriendEntity?
        var isShowingDeleteDialog = false
    }

    enum Action {
        case onAppear
        case backTapped

        case addTapped
        case editTapped(UUID)
        case updateEditingName(String)
        case selectEditingAvatar(String)
        case saveEditingTapped
        case cancelEditingTapped

        case deleteTapped(UUID)
        case confirmDeleteTapped
        case cancelDeleteTapped
    }

    @Published private(set) var state = State()

    private let friendRepository: FriendRepository
    private let onClose: () -> Void

    init(dependencies: AppDependencies, onClose: @escaping () -> Void = {}) {
        self.friendRepository = dependencies.friendRepository
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
        case .editTapped(let friendID):
            presentEditDialog(friendID: friendID)
        case .updateEditingName(let name):
            state.editingName = name
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

    var dialogTitle: String {
        state.editingFriendID == nil ? "Add Friend" : "Edit Friend"
    }

    private func loadFriends() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            state.friends = try fetchActiveFriends()
            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func presentAddDialog() {
        state.editingFriendID = nil
        state.editingName = ""
        state.editingAvatarAssetName = FriendAvatarOptions.defaultAssetName
        state.editValidationMessage = nil
        state.isShowingEditDialog = true
    }

    private func presentEditDialog(friendID: UUID) {
        guard let friend = state.friends.first(where: { $0.id == friendID }) else { return }
        state.editingFriendID = friend.id
        state.editingName = friend.name
        state.editingAvatarAssetName = FriendAvatarOptions.isValid(assetName: friend.avatarAssetName)
            ? (friend.avatarAssetName ?? FriendAvatarOptions.defaultAssetName)
            : FriendAvatarOptions.defaultAssetName
        state.editValidationMessage = nil
        state.isShowingEditDialog = true
    }

    private func saveEditing() {
        let trimmedName = state.editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            state.editValidationMessage = "Name is required."
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
            state.editValidationMessage = "A friend with this name already exists."
            return
        }

        let avatarAssetName = FriendAvatarOptions.isValid(assetName: state.editingAvatarAssetName)
            ? state.editingAvatarAssetName
            : FriendAvatarOptions.defaultAssetName

        do {
            if let editingID = state.editingFriendID {
                guard let existing = state.friends.first(where: { $0.id == editingID }) else {
                    throw RepositoryError.notFound
                }
                var updated = existing
                updated.name = trimmedName
                updated.avatarAssetName = avatarAssetName
                updated.isActive = true
                _ = try friendRepository.upsert(updated)
            } else {
                _ = try friendRepository.create(
                    name: trimmedName,
                    handle: nil,
                    avatarAssetName: avatarAssetName,
                    isActive: true
                )
            }

            dismissEditDialog()
            state.friends = try fetchActiveFriends()
            notifyFriendsDidChange()
            state.errorMessage = nil
        } catch {
            state.editValidationMessage = error.localizedDescription
        }
    }

    private func dismissEditDialog() {
        state.isShowingEditDialog = false
        state.editValidationMessage = nil
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
            state.friends = try fetchActiveFriends()
            notifyFriendsDidChange()
            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
            dismissDeleteDialog()
        }
    }

    private func dismissDeleteDialog() {
        state.pendingDeleteFriend = nil
        state.isShowingDeleteDialog = false
    }

    private func fetchActiveFriends() throws -> [FriendEntity] {
        try friendRepository.fetchActive().sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func notifyFriendsDidChange() {
        NotificationCenter.default.post(name: .friendsDidChange, object: nil)
    }
}
