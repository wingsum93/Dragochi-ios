//
//  DragonPlatformPill.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonPlatformPill: View {
    let platform: PlatformOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 22, weight: .regular))
                Text(platform.title)
                    .font(DragonTheme.current.font(.labelSmall))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Circle()
                        .fill(DragonTheme.current.color(.accentPrimary))
                        .frame(width: 6, height: 6)
                        .shadow(color: DragonTheme.current.color(.accentPrimary), radius: 6)
                        .padding(10)
                }
            }
        }
        .disabled(!platform.isEnabled)
        .buttonStyle(.plain)
        .opacity(platform.isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimary)
        }
        return DragonTheme.current.color(.textTertiary)
    }

    private var backgroundColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimaryDim)
        }
        return DragonTheme.current.color(.surfaceCard)
    }

    private var borderColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimary)
        }
        return DragonTheme.current.color(.borderSoft).opacity(0.5)
    }
}
