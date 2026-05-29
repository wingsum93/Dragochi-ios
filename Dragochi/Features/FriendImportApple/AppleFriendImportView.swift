//
//  AppleFriendImportView.swift
//  Dragochi
//
//  Created by Codex on 21/3/2026.
//

import SwiftUI

struct AppleFriendImportView: View {
    @StateObject private var store: AppleFriendImportViewModel
    @Environment(\.locale) private var locale

    init(store: AppleFriendImportViewModel) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.md)) {
                if store.state.selectedContacts.isEmpty {
                    Text("text_import_apple_initial_description")
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))

                    Button {
                        store.send(.importTapped)
                    } label: {
                        Text("button_import_from_apple")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DragonTheme.current.color(.accentPrimary))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("action.importFromAppleInImportScreen")
                } else {
                    selectedContactsSection
                    actionButtons
                }

                Spacer(minLength: 0)
            }
            .padding(DragonTheme.current.spacing(.lg))
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("screen.appleFriendImport")
            }
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
            .navigationTitle("title_import_friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DragonTheme.current.color(.bgBase), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityIdentifier("action.closeAppleFriendImport")
                }
            }
        }
        .sheet(isPresented: isShowingPicker) {
            AppleContactPickerRepresentable(
                onContactsSelected: { contacts in
                    store.send(.contactsSelected(contacts))
                },
                onCancel: {
                    store.send(.contactSelectionCancelled)
                }
            )
        }
        .alert("title_duplicate_friends_found", isPresented: isShowingDuplicateAlert) {
            Button("button_cancel", role: .cancel) {
                store.send(.cancelDuplicateImportTapped)
            }
            Button("button_confirm_import") {
                store.send(.confirmDuplicateImportTapped)
            }
        } message: {
            Text(
                L10n.format(
                    "text_import_duplicate_friends_confirm_format",
                    locale: locale,
                    Int64(store.state.duplicateCount)
                )
            )
        }
        .alert("title_import_friends", isPresented: isShowingFeedbackAlert) {
            Button("button_done", role: .cancel) {
                store.send(.dismissFeedbackAlert)
            }
        } message: {
            if let key = store.state.feedbackMessageKey {
                Text(L10n.string(key, locale: locale))
            } else if let message = store.state.feedbackMessage {
                Text(message)
            } else {
                Text("")
            }
        }
    }

    private var selectedContactsSection: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            Text("title_selected_contacts")
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    ForEach(Array(store.state.selectedContacts.enumerated()), id: \.element.id) { index, contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.format("text_contact_id_format", locale: locale, contact.id))
                                .font(DragonTheme.current.font(.gameCardLabel))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            Text(L10n.format("text_contact_full_name_format", locale: locale, contact.fullName))
                                .font(DragonTheme.current.font(.labelSmall))
                                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                            Text(L10n.format("text_contact_email_format", locale: locale, contact.email ?? "-"))
                                .font(DragonTheme.current.font(.gameCardLabel))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            Text(L10n.format("text_contact_phone_format", locale: locale, contact.phone ?? "-"))
                                .font(DragonTheme.current.font(.gameCardLabel))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DragonTheme.current.spacing(.sm))
                        .background(DragonTheme.current.color(.surfaceCard))
                        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                        .accessibilityIdentifier("row.appleImportContact.\(index)")
                    }
                }
            }
            .frame(maxHeight: 320)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: DragonTheme.current.spacing(.sm)) {
            Button {
                store.send(.reselectTapped)
            } label: {
                Text("button_reselect")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("action.reselectAppleContacts")

            Button {
                store.send(.confirmImportTapped)
            } label: {
                Text("button_confirm_import")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DragonTheme.current.color(.accentPrimary))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.state.isImporting)
            .accessibilityIdentifier("action.confirmAppleImport")
        }
    }

    private var isShowingPicker: Binding<Bool> {
        Binding(
            get: { store.state.isShowingPicker },
            set: { isPresented in
                if !isPresented {
                    store.send(.contactSelectionCancelled)
                }
            }
        )
    }

    private var isShowingDuplicateAlert: Binding<Bool> {
        Binding(
            get: { store.state.isShowingDuplicateAlert },
            set: { _ in }
        )
    }

    private var isShowingFeedbackAlert: Binding<Bool> {
        Binding(
            get: { store.state.isShowingFeedbackAlert },
            set: { isPresented in
                if !isPresented {
                    store.send(.dismissFeedbackAlert)
                }
            }
        )
    }
}
