//
//  AppToolbar.swift
//  Dragochi
//
//  Created by Codex on 21/7/2026.
//

import SwiftUI

struct AppToolbar: View {
    @Binding var selectedTab: AppTab
    let onAddTapped: () -> Void

    private let toolbarHeight: CGFloat = 72
    private let addButtonSize: CGFloat = 64

    private var totalHeight: CGFloat {
        toolbarHeight + addButtonSize / 2
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            toolbarBackground

            HStack(spacing: 0) {
                tabButton(.home, titleKey: "title_tab_home", iconName: "gamecontroller")
                tabButton(.history, titleKey: "title_tab_history", iconName: "clock.arrow.circlepath")

                Color.clear
                    .frame(width: addButtonSize + DragonTheme.current.spacing(.lg))
                    .accessibilityHidden(true)

                tabButton(.stats, titleKey: "title_tab_stats", iconName: "chart.bar")
                tabButton(.settings, titleKey: "title_tab_settings", iconName: "gearshape")
            }
            .frame(height: toolbarHeight)
            .padding(.horizontal, DragonTheme.current.spacing(.md))

            addButton
                .frame(height: totalHeight, alignment: .top)
        }
        .frame(height: totalHeight, alignment: .bottom)
    }

    private var toolbarBackground: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DragonTheme.current.color(.borderSoft))
                .frame(height: 1)
            DragonTheme.current.color(.surfaceCard)
        }
        .frame(height: toolbarHeight)
    }

    private var addButton: some View {
        Button(action: onAddTapped) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: addButtonSize, height: addButtonSize)
                .background(DragonTheme.current.color(.accentPrimary))
                .clipShape(Circle())
                .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.35), radius: 12, y: 4)
                .overlay {
                    Circle()
                        .stroke(DragonTheme.current.color(.bgBase), lineWidth: 4)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("button_add"))
        .accessibilityIdentifier("action.openAddSession")
    }

    private func tabButton(_ tab: AppTab, titleKey: LocalizedStringKey, iconName: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(titleKey)
                    .font(DragonTheme.current.font(.labelSmall))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(
                isSelected
                    ? DragonTheme.current.color(.textPrimary)
                    : DragonTheme.current.color(.textTertiary)
            )
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier(for: tab))
    }

    private func accessibilityIdentifier(for tab: AppTab) -> String {
        switch tab {
        case .home:
            return "tab.home.button"
        case .history:
            return "tab.history.button"
        case .stats:
            return "tab.stats.button"
        case .settings:
            return "tab.settings.button"
        }
    }
}

#if DEBUG
private struct AppToolbarPreview: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        VStack {
            Spacer()
            AppToolbar(selectedTab: $selectedTab, onAddTapped: {})
        }
        .background(DragonTheme.current.color(.bgBase))
    }
}

#Preview("App Toolbar") {
    AppToolbarPreview()
}
#endif
