//
//  SettingView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
import UIKit
import MessageUI

struct SettingView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let makeAppleFriendImportViewModel: (@escaping () -> Void) -> AppleFriendImportViewModel
    let onOpenGameSettings: () -> Void
    let onOpenFriendSettings: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale
    @State private var isShowingOpenSourceLicenses = false
    @State private var isShowingFriendImportOptions = false
    @State private var isShowingGoogleImportComingSoon = false
    @State private var isShowingAppleFriendImport = false

    init(
        viewModel: SettingsViewModel,
        makeAppleFriendImportViewModel: @escaping (@escaping () -> Void) -> AppleFriendImportViewModel,
        onOpenGameSettings: @escaping () -> Void = {},
        onOpenFriendSettings: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.makeAppleFriendImportViewModel = makeAppleFriendImportViewModel
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
                                    get: { viewModel.state.isICloudSyncOn },
                                    set: { viewModel.send(.toggleICloud($0)) }
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

                        if let date = viewModel.state.lastBackupDate {
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
                                viewModel.send(.exportTapped)
                            } label: {
                                Text(
                                    L10n.string(
                                        viewModel.state.isExporting ? "button_exporting" : "button_export",
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
                            .disabled(viewModel.state.isExporting)

                            Button {
                                viewModel.send(.importTapped)
                            } label: {
                                Text(
                                    L10n.string(
                                        viewModel.state.isImporting ? "button_importing" : "button_import",
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
                            .disabled(viewModel.state.isImporting)
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
                            openPerAppLanguageSettings()
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

                        Button {
                            isShowingFriendImportOptions = true
                        } label: {
                            HStack {
                                Text("button_import_friends")
                                    .font(DragonTheme.current.font(.labelSmall))
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Spacer()

                                Image(systemName: "square.and.arrow.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("action.openFriendImportOptionsFromSettings")
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

                        Button {
                            viewModel.send(.reportIssueTapped(canSendMail: MFMailComposeViewController.canSendMail()))
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.bubble")
                                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                                Text("button_report_issue_to_developer")
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
                        .accessibilityIdentifier("action.reportIssueToDeveloper")
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
        .onAppear { viewModel.send(.onAppear) }
        .sheet(isPresented: $isShowingOpenSourceLicenses) {
            openSourceLicensesSheet
        }
        .sheet(
            item: Binding(
                get: { viewModel.state.issueReportDraft },
                set: { newValue in
                    if newValue == nil {
                        viewModel.send(.clearIssueReportDraft)
                    }
                }
            )
        ) { draft in
            ReportIssueMailComposeSheet(
                draft: draft,
                onFinish: {
                    viewModel.send(.clearIssueReportDraft)
                }
            )
        }
        .sheet(isPresented: $isShowingFriendImportOptions) {
            FriendImportOptionSheet(
                onImportFromApple: {
                    isShowingFriendImportOptions = false
                    DispatchQueue.main.async {
                        isShowingAppleFriendImport = true
                    }
                },
                onImportFromGoogle: {
                    isShowingFriendImportOptions = false
                    DispatchQueue.main.async {
                        isShowingGoogleImportComingSoon = true
                    }
                },
                onCancel: {
                    isShowingFriendImportOptions = false
                }
            )
        }
        .fullScreenCover(isPresented: $isShowingAppleFriendImport) {
            AppleFriendImportFullPage(
                viewModel: makeAppleFriendImportViewModel(
                    { isShowingAppleFriendImport = false }
                )
            )
        }
        .alert("title_import_friends", isPresented: $isShowingGoogleImportComingSoon) {
            Button("button_done", role: .cancel) {}
        } message: {
            Text("text_google_import_coming_soon")
        }
        .alert(
            "title_mail_not_available",
            isPresented: Binding(
                get: { viewModel.state.isShowingMailUnavailableAlert },
                set: { isPresented in
                    if !isPresented {
                        viewModel.send(.dismissMailUnavailableAlert)
                    }
                }
            )
        ) {
            Button("button_copy_developer_email") {
                UIPasteboard.general.string = SettingsViewModel.reportIssueRecipientEmail
            }
            Button("button_open_mail_app") {
                openSupportMailto()
            }
            Button("button_cancel", role: .cancel) {
                viewModel.send(.dismissMailUnavailableAlert)
            }
        } message: {
            Text("text_mail_not_available")
        }
    }

    private var openSourceLicensesSheet: some View {
        NavigationStack {
            List(openSourceLicenses) { (license: OpenSourceLicenseItem) in
                Button {
                    guard let url = license.url else { return }
                    openURL(url)
                } label: {
                    openSourceLicenseRow(license)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("title_open_source_license")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func openSourceLicenseRow(_ license: OpenSourceLicenseItem) -> some View {
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

    private func openPerAppLanguageSettings() {
        guard let fallbackSettingsURL = URL(string: UIApplication.openSettingsURLString) else { return }

        var candidateURLs: [URL] = []
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            if let languageURL = URL(string: "App-prefs:root=\(bundleIdentifier)&path=LANGUAGE") {
                candidateURLs.append(languageURL)
                print("er url: \(languageURL)")
            }
            if let appSettingsURL = URL(string: "App-prefs:root=\(bundleIdentifier)") {
                print("er url: \(appSettingsURL)")
                candidateURLs.append(appSettingsURL)
            }
        }
        candidateURLs.append(fallbackSettingsURL)

        openSettingsURL(candidateURLs, at: 0)
    }

    private func openSettingsURL(_ urls: [URL], at index: Int) {
        guard index < urls.count else { return }

        UIApplication.shared.open(urls[index], options: [:]) { didOpen in
            if !didOpen {
                self.openSettingsURL(urls, at: index + 1)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openSupportMailto() {
        guard let url = URL(string: "mailto:\(SettingsViewModel.reportIssueRecipientEmail)") else { return }
        openURL(url)
    }
}

private struct OpenSourceLicenseItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let url: URL?
}
