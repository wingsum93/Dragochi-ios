//
//  GameSettingsView.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import SwiftUI

struct GameSettingsView: View {
    @StateObject private var store: GameSettingsStore

    init(store: GameSettingsStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DragonTheme.current.spacing(.md)) {
                searchField

                if store.filteredCatalog.isEmpty {
                    Spacer()
                    Text("No games found")
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

                                    if store.state.enabledRemoteIDs.contains(game.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("row.gameSettings.\(game.id)")
                            .listRowBackground(DragonTheme.current.color(.bgBase))
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
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        store.send(.closeTapped)
                    }
                    .accessibilityIdentifier("action.closeGameSettings")
                }
            }
        }
        .accessibilityIdentifier("screen.gameSettings")
        .onAppear { store.send(.onAppear) }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            TextField(
                "search game name",
                text: Binding(
                    get: { store.state.query },
                    set: { store.send(.updateQuery($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(DragonTheme.current.color(.textPrimary))

            Button {
                if store.state.query.isEmpty {
                    return
                }
                store.send(.clearQuery)
            } label: {
                Image(systemName: store.state.query.isEmpty ? "magnifyingglass" : "xmark.circle.fill")
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("action.clearGameSearch")
        }
        .padding(.horizontal, 12)
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
}
