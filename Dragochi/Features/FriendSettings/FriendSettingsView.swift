//
//  FriendSettingsView.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct FriendSettingsView: View {
    @StateObject private var viewModel: FriendSettingsViewModel
    @Environment(\.locale) private var locale

    init(viewModel: FriendSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private let avatarColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let emptyStateAnimationName = "no_data_found"
    private let emptyStateAnimationSize: CGFloat = 180

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                if let errorMessage = viewModel.state.errorMessage {
                    Text(errorMessage)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DragonTheme.current.spacing(.lg))
                        .padding(.bottom, DragonTheme.current.spacing(.sm))
                }
            }
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("screen.friendSettings")
            }
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
            .navigationTitle("title_friend_list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DragonTheme.current.color(.bgBase), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityIdentifier("action.backFriendSettings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.send(.toggleReorderMode)
                    } label: {
                        if viewModel.state.isReorderMode {
                            Text("button_done")
                        } else {
                            Text("Reorder")
                        }
                    }
                    .accessibilityIdentifier("action.toggleFriendReorder")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.state.isReorderMode {
                        Button {
                            viewModel.send(.addTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("action.addFriend")
                    }
                }
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .sheet(isPresented: isShowingEditDialog) {
            editDialog
                .presentationDetents([.medium, .large])
        }
        .alert("title_delete_friend", isPresented: isShowingDeleteDialog) {
            Button("button_cancel", role: .cancel) {
                viewModel.send(.cancelDeleteTapped)
            }
            Button("button_delete", role: .destructive) {
                viewModel.send(.confirmDeleteTapped)
            }
        } message: {
            Text("text_confirm_remove_friend")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            loadingView
        } else if viewModel.state.friends.isEmpty {
            emptyStateView
        } else {
            friendsListView
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var emptyStateView: some View {
        VStack(spacing: DragonTheme.current.spacing(.md)) {
            emptyStateAnimation
                .frame(width: emptyStateAnimationSize, height: emptyStateAnimationSize)

            VStack(spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_no_friends_yet")
                    .font(DragonTheme.current.font(.body))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))

                Text("text_tap_add_first_teammate")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, DragonTheme.current.spacing(.lg))
    }

    @ViewBuilder
    private var emptyStateAnimation: some View {
        if DragonLottieView.canLoadAnimation(named: emptyStateAnimationName) {
            DragonLottieView(animationName: emptyStateAnimationName)
        } else {
            Circle()
                .fill(DragonTheme.current.color(.surfaceCard))
                .overlay {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
        }
    }

    private var friendsListView: some View {
        List {
            ForEach(viewModel.state.friends) { friend in
                HStack(spacing: DragonTheme.current.spacing(.md)) {
                    avatar(for: friend.avatarAssetName)

                    Text(friend.name)
                        .font(DragonTheme.current.font(.body))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))

                    Spacer()

                    if !viewModel.state.isReorderMode {
                        Button {
                            viewModel.send(.editTapped(friend.id))
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.editFriend.\(friend.id.uuidString)")

                        Button(role: .destructive) {
                            viewModel.send(.deleteTapped(friend.id))
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.deleteFriend.\(friend.id.uuidString)")
                    }
                }
                .padding(.vertical, 6)
                .accessibilityIdentifier("row.friend.\(friend.id.uuidString)")
                .listRowBackground(DragonTheme.current.color(.bgBase))
            }
            .onMove { source, destination in
                viewModel.send(.moveFriends(source, destination))
            }
            .moveDisabled(!viewModel.state.isReorderMode)
        }
        .environment(\.editMode, .constant(viewModel.state.isReorderMode ? .active : .inactive))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func avatar(for assetName: String?) -> some View {
        Group {
            if let assetName, FriendAvatarOptions.isValid(assetName: assetName) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    }
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }

    private var editDialog: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.md)) {
                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_name")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        TextField(
                            L10n.string("text_enter_friend_name", locale: locale),
                            text: Binding(
                                get: { viewModel.state.editingName },
                                set: { viewModel.send(.updateEditingName($0)) }
                            )
                        )
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(DragonTheme.current.color(.surfaceCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                                .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                        .accessibilityIdentifier("input.friendName")
                    }

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_icon")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        LazyVGrid(columns: avatarColumns, spacing: 12) {
                            ForEach(FriendAvatarOptions.assetNames, id: \.self) { assetName in
                                Button {
                                    viewModel.send(.selectEditingAvatar(assetName))
                                } label: {
                                    ZStack {
                                        Image(assetName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())

                                        Circle()
                                            .stroke(
                                                viewModel.state.editingAvatarAssetName == assetName
                                                    ? DragonTheme.current.color(.accentPrimary)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                            .frame(width: 52, height: 52)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("action.selectFriendAvatar.\(assetName)")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("Note")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        FriendNoteTextView(
                            text: Binding(
                                get: { viewModel.state.editingNote },
                                set: { viewModel.send(.updateEditingNote($0)) }
                            )
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(DragonTheme.current.color(.surfaceCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                                .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                    }

                    if let validationMessageKey = viewModel.state.editValidationMessageKey {
                        Text(L10n.string(validationMessageKey, locale: locale))
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(.red)
                    } else if let validationMessage = viewModel.state.editValidationMessage {
                        Text(validationMessage)
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(.red)
                    }
                }
                .padding(DragonTheme.current.spacing(.lg))
            }
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
            .navigationTitle(L10n.string(viewModel.dialogTitleKey, locale: locale))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("button_cancel") {
                        viewModel.send(.cancelEditingTapped)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_save") {
                        viewModel.send(.saveEditingTapped)
                    }
                    .accessibilityIdentifier("action.saveFriend")
                }
            }
        }
    }

    private var isShowingEditDialog: Binding<Bool> {
        Binding(
            get: { viewModel.state.isShowingEditDialog },
            set: { isPresented in
                if !isPresented {
                    viewModel.send(.cancelEditingTapped)
                }
            }
        )
    }

    private var isShowingDeleteDialog: Binding<Bool> {
        Binding(
            get: { viewModel.state.isShowingDeleteDialog },
            set: { isPresented in
                if !isPresented {
                    viewModel.send(.cancelDeleteTapped)
                }
            }
        )
    }
}
