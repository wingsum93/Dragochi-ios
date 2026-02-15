//
//  SettingsView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.openURL) private var openURL
    @State private var isShowingOpenSourceLicenses = false

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

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                        Text("About")
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))

                        Button {
                            isShowingOpenSourceLicenses = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Text("Open Source License")
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
                .navigationTitle("Open Source License")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
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
