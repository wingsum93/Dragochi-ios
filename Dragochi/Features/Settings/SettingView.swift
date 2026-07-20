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
    @ObservedObject var viewModel: SettingViewModel
    let makeAppleFriendImportViewModel: (@escaping () -> Void) -> AppleFriendImportViewModel
    let onOpenGameSettings: () -> Void
    let onOpenFriendSettings: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    init(
        viewModel: SettingViewModel,
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

                    SettingsICloudSection(
                        isICloudSyncOn: viewModel.state.isICloudSyncOn,
                        onToggleICloud: { viewModel.send(.toggleICloud($0)) }
                    )

                    SettingsBackupSection(
                        lastBackupDateText: viewModel.state.lastBackupDate.map(formatDate),
                        isExporting: viewModel.state.isExporting,
                        isImporting: viewModel.state.isImporting,
                        locale: locale,
                        onExport: { viewModel.send(.exportTapped) },
                        onImport: { viewModel.send(.importTapped) }
                    )

                    SettingsLanguageSection(onOpenLanguageSettings: openPerAppLanguageSettings)

                    SettingsGameSection(onOpenGameSettings: onOpenGameSettings)

                    SettingsFriendSection(
                        onOpenFriendSettings: onOpenFriendSettings,
                        onOpenFriendImportOptions: { viewModel.send(.friendImportOptionsTapped) }
                    )

                    SettingsAboutSection(
                        onOpenSourceLicenses: { viewModel.send(.openSourceLicensesTapped) },
                        onReportIssue: {
                            viewModel.send(.reportIssueTapped(canSendMail: MFMailComposeViewController.canSendMail()))
                        }
                    )
                }
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.top, DragonTheme.current.spacing(.lg))
                .padding(.bottom, DragonTheme.current.spacing(.xl))
            }
        }
        .accessibilityIdentifier("screen.settings")
        .onAppear { viewModel.send(.onAppear) }
        .sheet(item: sheetPresentation) { presentation in
            sheet(for: presentation)
        }
        .fullScreenCover(item: appleFriendImportPresentation) { _ in
            AppleFriendImportFullPage(
                viewModel: makeAppleFriendImportViewModel(
                    { viewModel.send(.clearPresentation) }
                )
            )
        }
        .alert("title_import_friends", isPresented: isShowingGoogleImportComingSoon) {
            Button("button_done", role: .cancel) {
                viewModel.send(.clearPresentation)
            }
        } message: {
            Text("text_google_import_coming_soon")
        }
        .alert(
            "title_mail_not_available",
            isPresented: isShowingMailUnavailableAlert
        ) {
            Button("button_copy_developer_email") {
                UIPasteboard.general.string = SettingViewModel.reportIssueRecipientEmail
            }
            Button("button_open_mail_app") {
                openSupportMailto()
            }
            Button("button_cancel", role: .cancel) {
                viewModel.send(.clearPresentation)
            }
        } message: {
            Text("text_mail_not_available")
        }
    }

    @ViewBuilder
    private func sheet(for presentation: SettingsPresentation) -> some View {
        switch presentation {
        case .openSourceLicenses:
            openSourceLicensesSheet
        case .friendImportOptions:
            FriendImportOptionSheet(
                onImportFromApple: { viewModel.send(.appleFriendImportSelected) },
                onImportFromGoogle: { viewModel.send(.googleFriendImportSelected) }
            )
        case .issueReport(let draft):
            ReportIssueMailComposeSheet(
                draft: draft,
                onFinish: {
                    viewModel.send(.clearPresentation)
                }
            )
        case .appleFriendImport, .googleImportComingSoon, .mailUnavailable:
            EmptyView()
        }
    }

    private var sheetPresentation: Binding<SettingsPresentation?> {
        Binding(
            get: {
                switch viewModel.state.presentation {
                case .openSourceLicenses, .friendImportOptions, .issueReport:
                    return viewModel.state.presentation
                case .appleFriendImport, .googleImportComingSoon, .mailUnavailable, nil:
                    return nil
                }
            },
            set: { presentation in
                guard presentation == nil else { return }
                switch viewModel.state.presentation {
                case .openSourceLicenses, .friendImportOptions, .issueReport:
                    viewModel.send(.clearPresentation)
                case .appleFriendImport, .googleImportComingSoon, .mailUnavailable, nil:
                    break
                }
            }
        )
    }

    private var appleFriendImportPresentation: Binding<SettingsPresentation?> {
        Binding(
            get: {
                guard case .appleFriendImport = viewModel.state.presentation else { return nil }
                return viewModel.state.presentation
            },
            set: { presentation in
                if presentation == nil {
                    viewModel.send(.clearPresentation)
                }
            }
        )
    }

    private var isShowingGoogleImportComingSoon: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentation == .googleImportComingSoon },
            set: { isPresented in
                if !isPresented {
                    viewModel.send(.clearPresentation)
                }
            }
        )
    }

    private var isShowingMailUnavailableAlert: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentation == .mailUnavailable },
            set: { isPresented in
                if !isPresented {
                    viewModel.send(.clearPresentation)
                }
            }
        )
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
        guard let url = URL(string: "mailto:\(SettingViewModel.reportIssueRecipientEmail)") else { return }
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

private struct SettingsICloudSection: View {
    let isICloudSyncOn: Bool
    let onToggleICloud: (Bool) -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.md)) {
                HStack {
                    Text("title_icloud_sync")
                        .font(DragonTheme.current.font(.titleSection))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { isICloudSyncOn },
                            set: onToggleICloud
                        )
                    )
                    .labelsHidden()
                    .tint(DragonTheme.current.color(.accentPrimary))
                }

                Text("text_icloud_sync_description")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
        }
    }
}

private struct SettingsBackupSection: View {
    let lastBackupDateText: String?
    let isExporting: Bool
    let isImporting: Bool
    let locale: Locale
    let onExport: () -> Void
    let onImport: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_backup")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                if let lastBackupDateText {
                    Text(L10n.format("text_backup_last_export_format", locale: locale, lastBackupDateText))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                } else {
                    Text("text_no_backup_yet")
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }

                HStack(spacing: DragonTheme.current.spacing(.sm)) {
                    Button(action: onExport) {
                        Text(L10n.string(isExporting ? "button_exporting" : "button_export", locale: locale))
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DragonTheme.current.color(.accentPrimary))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting)

                    Button(action: onImport) {
                        Text(L10n.string(isImporting ? "button_importing" : "button_import", locale: locale))
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DragonTheme.current.color(.surfaceCard))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                }
            }
        }
    }
}

private struct SettingsLanguageSection: View {
    let onOpenLanguageSettings: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_language")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                Text("text_per_app_language_description")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))

                SettingsNavigationRow(
                    titleKey: "title_per_app_language",
                    accessibilityIdentifier: "action.openPerAppLanguageSettings",
                    action: onOpenLanguageSettings
                )
            }
        }
        .accessibilityIdentifier("section.settingsLanguage")
    }
}

private struct SettingsGameSection: View {
    let onOpenGameSettings: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_game")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                SettingsNavigationRow(
                    titleKey: "title_game_settings_temp",
                    accessibilityIdentifier: "action.openGameSettingsFromSettings",
                    action: onOpenGameSettings
                )
            }
        }
    }
}

private struct SettingsFriendSection: View {
    let onOpenFriendSettings: () -> Void
    let onOpenFriendImportOptions: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_friend")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                SettingsNavigationRow(
                    titleKey: "title_friend_list",
                    accessibilityIdentifier: "action.openFriendSettingsFromSettings",
                    action: onOpenFriendSettings
                )

                SettingsNavigationRow(
                    titleKey: "button_import_friends",
                    trailingIconName: "square.and.arrow.down",
                    accessibilityIdentifier: "action.openFriendImportOptionsFromSettings",
                    action: onOpenFriendImportOptions
                )
            }
        }
    }
}

private struct SettingsAboutSection: View {
    let onOpenSourceLicenses: () -> Void
    let onReportIssue: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Text("title_about")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                SettingsNavigationRow(
                    leadingIconName: "doc.text",
                    titleKey: "title_open_source_license",
                    accessibilityIdentifier: nil,
                    action: onOpenSourceLicenses
                )

                SettingsNavigationRow(
                    leadingIconName: "exclamationmark.bubble",
                    titleKey: "button_report_issue_to_developer",
                    accessibilityIdentifier: "action.reportIssueToDeveloper",
                    action: onReportIssue
                )
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(DragonTheme.current.spacing(.md))
            .background(DragonTheme.current.color(.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
    }
}

private struct SettingsNavigationRow: View {
    var leadingIconName: String? = nil
    let titleKey: LocalizedStringKey
    var trailingIconName = "chevron.right"
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let leadingIconName {
                    Image(systemName: leadingIconName)
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))
                }

                Text(titleKey)
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                Spacer()

                Image(systemName: trailingIconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}

#if DEBUG
@MainActor
private enum SettingViewPreviewFactory {
    static func makeView() -> SettingView {
        let sessionRepository = FakeSessionRepository()
        let gameRepository = FakeGameRepository(games: PreviewFixtures.games)
        let friendRepository = FakeFriendRepository(friends: PreviewFixtures.friends)
        let viewModel = SettingViewModel(
            backupService: StubBackupService(
                sessionRepository: sessionRepository,
                gameRepository: gameRepository,
                friendRepository: friendRepository
            ),
            auditLogger: PreviewAuditLoggerFixture()
        )

        return SettingView(
            viewModel: viewModel,
            makeAppleFriendImportViewModel: { onClose in
                AppleFriendImportViewModel(
                    friendRepository: friendRepository,
                    auditLogger: PreviewAuditLoggerFixture(),
                    onClose: onClose
                )
            }
        )
    }
}

#Preview("Setting View") {
    SettingViewPreviewFactory.makeView()
}
#endif
