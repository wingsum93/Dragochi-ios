//
//  GameSettingsView.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import SwiftUI

struct GameSettingsView: View {
    @StateObject private var store: GameSettingsViewModel
    @Environment(\.locale) private var locale
    private let searchContentSpacing: CGFloat = 8
    private let searchIconWidth: CGFloat = 16
    private let searchTrailingIconWidth: CGFloat = 16
    private let searchInnerHorizontalPadding: CGFloat = 12
    private let separatorGap: CGFloat = 0

    init(store: GameSettingsViewModel) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DragonTheme.current.spacing(.md)) {
                searchField

                if store.filteredCatalog.isEmpty {
                    Spacer()
                    Text("title_no_games_found")
                        .font(DragonTheme.current.font(.body))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    Spacer()
                } else {
                    List {
                        ForEach(store.filteredCatalog) { game in
                            Button {
                                store.send(.toggle(remoteID: game.id))
                            } label: {
                                HStack {
                                    Text(game.name)
                                        .font(DragonTheme.current.font(.body))
                                        .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                    Spacer()

                                    if store.state.draftEnabledRemoteIDs.contains(game.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                                            .padding(.trailing, checkmarkTrailingInset)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("row.gameSettings.\(game.id)")
                            .listRowBackground(DragonTheme.current.color(.bgBase))
                            .listRowInsets(
                                EdgeInsets(
                                    top: 0,
                                    leading: alignedRowTextLeading,
                                    bottom: 0,
                                    trailing: DragonTheme.current.spacing(.lg)
                                )
                            )
                            .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
                                dimensions[.trailing] - rowSeparatorTrailingInset
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }

                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DragonTheme.current.spacing(.lg))
                        .padding(.bottom, DragonTheme.current.spacing(.sm))
                }
            }
            .padding(.top, DragonTheme.current.spacing(.sm))
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
            .navigationTitle("title_game_settings")
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
                    .accessibilityIdentifier("action.backGameSettings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_done") {
                        store.send(.doneTapped)
                    }
                    .accessibilityIdentifier("action.closeGameSettings")
                }
            }
        }
        .accessibilityIdentifier("screen.gameSettings")
        .onAppear { store.send(.onAppear) }
        .alert("title_confirm_change", isPresented: isShowingConfirmChangesDialog) {
            Button("button_no", role: .cancel) {
                store.send(.cancelSaveChanges)
            }
            Button("button_yes") {
                store.send(.confirmSaveChanges)
            }
        } message: {
            Text("text_apply_changes_selected_games")
        }
    }

    private var searchField: some View {
        HStack(spacing: searchContentSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                .frame(width: searchIconWidth)

            TextField(
                L10n.string("text_search_game_name", locale: locale),
                text: Binding(
                    get: { store.state.query },
                    set: { store.send(.updateQuery($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(DragonTheme.current.color(.textPrimary))

            if !store.state.query.isEmpty {
                Button {
                    store.send(.clearQuery)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        .frame(width: searchTrailingIconWidth)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("action.clearGameSearch")
            }
        }
        .padding(.horizontal, searchInnerHorizontalPadding)
        .padding(.vertical, 10)
        .background(DragonTheme.current.color(.surfaceCard))
        .overlay(
            RoundedRectangle(cornerRadius: DragonTheme.current.radius(.pill), style: .continuous)
                .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.pill), style: .continuous))
        .padding(.horizontal, DragonTheme.current.spacing(.lg))
        .accessibilityIdentifier("input.gameSearch")
    }

    private var alignedRowTextLeading: CGFloat {
        DragonTheme.current.spacing(.lg) + searchInnerHorizontalPadding + searchIconWidth + searchContentSpacing
    }

    private var rowSeparatorTrailingInset: CGFloat {
        DragonTheme.current.spacing(.lg) + searchInnerHorizontalPadding + searchTrailingIconWidth + separatorGap
    }

    private var checkmarkTrailingInset: CGFloat {
        max(0, rowSeparatorTrailingInset - DragonTheme.current.spacing(.lg))
    }

    private var isShowingConfirmChangesDialog: Binding<Bool> {
        Binding(
            get: { store.state.isShowingConfirmChangesDialog },
            set: { isPresented in
                if !isPresented {
                    store.send(.cancelSaveChanges)
                }
            }
        )
    }
}
