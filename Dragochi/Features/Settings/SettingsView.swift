//
//  SettingsView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
                    Text("Settings")
                        .font(DragonTheme.current.font(.titleSection))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.md)) {
                        HStack {
                            Text("iCloud Sync")
                                .font(DragonTheme.current.font(.titleSection))
                                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { store.state.isICloudSyncOn },
                                    set: { store.send(.toggleICloud($0)) }
                                )
                            )
                            .labelsHidden()
                            .tint(DragonTheme.current.color(.accentPrimary))
                        }

                        Text("Sync across devices (local-only toggle for now).")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("Backup")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        if let date = store.state.lastBackupDate {
                            Text("Last export: \(formatDate(date))")
                                .font(DragonTheme.current.font(.labelSmall))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        } else {
                            Text("No backup created yet.")
                                .font(DragonTheme.current.font(.labelSmall))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        }

                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            Button {
                                store.send(.exportTapped)
                            } label: {
                                Text(store.state.isExporting ? "Exporting..." : "Export")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DragonTheme.current.color(.accentPrimary))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(store.state.isExporting)

                            Button {
                                store.send(.importTapped)
                            } label: {
                                Text(store.state.isImporting ? "Importing..." : "Import")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DragonTheme.current.color(.surfaceCard))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(store.state.isImporting)
                        }
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                }
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.top, DragonTheme.current.spacing(.lg))
                .padding(.bottom, 80)
            }
        }
        .accessibilityIdentifier("screen.settings")
        .onAppear { store.send(.onAppear) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
