//
//  DragonSectionHeader.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonSectionHeader: View {
    let title: String
    let trailingText: String?
    let trailingAction: (() -> Void)?

    init(
        title: String,
        trailingText: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.trailingText = trailingText
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack {
            Text(title)
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))

            Spacer()

            if let trailingText {
                if let trailingAction {
                    Button(trailingText, action: trailingAction)
                        .buttonStyle(.plain)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                } else {
                    Text(trailingText)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
            }
        }
    }
}
