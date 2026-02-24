//
//  SettingsView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    let onOpenGameSettings: () -> Void
    let onOpenFriendSettings: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale
    @State private var isShowingOpenSourceLicenses = false

    init(
        store: SettingsStore,
        onOpenGameSettings: @escaping () -> Void = {},
        onOpenFriendSettings: @escaping () -> Void = {}
    ) {
        self.store = store
        self.onOpenGameSettings = onOpenGameSettings
        self.onOpenFriendSettings = onOpenFriendSettings
    }

    private let openSourceLicenses: [OpenSourceLicenseItem] = [
        .init(
            icon: "swift",
            title: "Swift",
            subtitle: "Apache License 2.0",
            url: URL(string: "https://github.com/swiftlang/swift/blob/main/LICENSE.txt")
        ),
        .init(
            icon: "hammer.fill",
            title: "swift-collections",
            subtitle: "Apache License 2.0",
            url: URL(string: "https://github.com/apple/swift-collections/blob/main/LICENSE.txt")
        )
    ]

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
                    Text("title_settings")
                        .font(DragonTheme.current.font(.titleSection))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.md)) {
                        HStack {
                            Text("title_icloud_sync")
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

                        Text("text_icloud_sync_description")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_backup")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        if let date = store.state.lastBackupDate {
                            Text(L10n.format("text_backup_last_export_format", locale: locale, formatDate(date)))
                                .font(DragonTheme.current.font(.labelSmall))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        } else {
                            Text("text_no_backup_yet")
                                .font(DragonTheme.current.font(.labelSmall))
                                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                        }

                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            Button {
                                store.send(.exportTapped)
                            } label: {
                                Text(
                                    L10n.string(
                                        store.state.isExporting ? "button_exporting" : "button_export",
                                        locale: locale
                                    )
                                )
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
                                Text(
                                    L10n.string(
                                        store.state.isImporting ? "button_importing" : "button_import",
                                        locale: locale
                                    )
                                )
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

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_language")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        Text("text_per_app_language_description")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))

                        Button {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(settingsURL)
                        } label: {
                            HStack {
                                Text("title_per_app_language")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("action.openPerAppLanguageSettings")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.openPerAppLanguageSettings")
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                    .accessibilityIdentifier("section.settingsLanguage")

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_game")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        Button {
                            onOpenGameSettings()
                        } label: {
                            HStack {
                                Text("title_game_settings_temp")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.openGameSettingsFromSettings")
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_friend")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        Button {
                            onOpenFriendSettings()
                        } label: {
                            HStack {
                                Text("title_friend_list")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.openFriendSettingsFromSettings")
                    }
                    .padding(DragonTheme.current.spacing(.md))
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("title_about")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        Button {
                            isShowingOpenSourceLicenses = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Text("title_open_source_license")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
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
        .sheet(isPresented: $isShowingOpenSourceLicenses) {
            NavigationStack {
                List(openSourceLicenses) { (license: OpenSourceLicenseItem) in
                    Button {
                        guard let url = license.url else { return }
                        openURL(url)
                    } label: {
                        HStack(spacing: DragonTheme.current.spacing(.md)) {
                            Image(systemName: license.icon)
                                .frame(width: 24)
                                .foregroundStyle(DragonTheme.current.color(.textPrimary))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(license.title)
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                                Text(license.subtitle)
                                    .font(DragonTheme.current.font(.gameCardLabel))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("title_open_source_license")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct OpenSourceLicenseItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let url: URL?
}
