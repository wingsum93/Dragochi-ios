//
//  FriendSettingsView.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct FriendSettingsView: View {
    @StateObject private var store: FriendSettingsStore

    init(store: FriendSettingsStore) {
        _store = StateObject(wrappedValue: store)
    }

    private let avatarColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let emptyStateAnimationName = "no_data_found"
    private let emptyStateAnimationSize: CGFloat = 180

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                if let errorMessage = store.state.errorMessage {
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
            .navigationTitle("Friend List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DragonTheme.current.color(.bgBase), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityIdentifier("action.backFriendSettings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.addTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("action.addFriend")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: isShowingEditDialog) {
            editDialog
                .presentationDetents([.medium, .large])
        }
        .alert("Delete Friend", isPresented: isShowingDeleteDialog) {
            Button("Cancel", role: .cancel) {
                store.send(.cancelDeleteTapped)
            }
            Button("Delete", role: .destructive) {
                store.send(.confirmDeleteTapped)
            }
        } message: {
            Text("Are you sure you want to remove this friend?")
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.state.isLoading {
            loadingView
        } else if store.state.friends.isEmpty {
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
                Text("No friends yet")
                    .font(DragonTheme.current.font(.body))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))

                Text("Tap + to add your first teammate.")
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
            ForEach(store.state.friends) { friend in
                HStack(spacing: DragonTheme.current.spacing(.md)) {
                    avatar(for: friend.avatarAssetName)

                    Text(friend.name)
                        .font(DragonTheme.current.font(.body))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))

                    Spacer()

                    Button {
                        store.send(.editTapped(friend.id))
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("action.editFriend.\(friend.id.uuidString)")

                    Button(role: .destructive) {
                        store.send(.deleteTapped(friend.id))
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("action.deleteFriend.\(friend.id.uuidString)")
                }
                .padding(.vertical, 6)
                .accessibilityIdentifier("row.friend.\(friend.id.uuidString)")
                .listRowBackground(DragonTheme.current.color(.bgBase))
            }
        }
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
                        Text("Name")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        TextField(
                            "Enter friend name",
                            text: Binding(
                                get: { store.state.editingName },
                                set: { store.send(.updateEditingName($0)) }
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
                        Text("Icon")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        LazyVGrid(columns: avatarColumns, spacing: 12) {
                            ForEach(FriendAvatarOptions.assetNames, id: \.self) { assetName in
                                Button {
                                    store.send(.selectEditingAvatar(assetName))
                                } label: {
                                    ZStack {
                                        Image(assetName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())

                                        Circle()
                                            .stroke(
                                                store.state.editingAvatarAssetName == assetName
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

                    if let validationMessage = store.state.editValidationMessage {
                        Text(validationMessage)
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(.red)
                    }
                }
                .padding(DragonTheme.current.spacing(.lg))
            }
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
            .navigationTitle(store.dialogTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        store.send(.cancelEditingTapped)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.send(.saveEditingTapped)
                    }
                    .accessibilityIdentifier("action.saveFriend")
                }
            }
        }
    }

    private var isShowingEditDialog: Binding<Bool> {
        Binding(
            get: { store.state.isShowingEditDialog },
            set: { isPresented in
                if !isPresented {
                    store.send(.cancelEditingTapped)
                }
            }
        )
    }

    private var isShowingDeleteDialog: Binding<Bool> {
        Binding(
            get: { store.state.isShowingDeleteDialog },
            set: { isPresented in
                if !isPresented {
                    store.send(.cancelDeleteTapped)
                }
            }
        )
    }
}
