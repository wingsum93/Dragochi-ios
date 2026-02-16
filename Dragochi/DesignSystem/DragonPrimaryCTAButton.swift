//
//  DragonPrimaryCTAButton.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonPrimaryCTAButton: View {
    let title: String
    let icon: String?
    let state: ControlState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if state == .loading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(title)
                        .font(DragonTheme.current.font(.cta))
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(backgroundColor)
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .loading)
    }

    private var backgroundColor: Color {
        switch state {
        case .enabled:
            return DragonTheme.current.color(.accentPrimary)
        case .pressed:
            return DragonTheme.current.color(.accentPrimary).opacity(0.85)
        case .disabled, .loading:
            return DragonTheme.current.color(.accentPrimary).opacity(0.55)
        }
    }

    private var shadowColor: Color {
        state == .enabled ? DragonTheme.current.color(.accentPrimary).opacity(0.35) : .clear
    }
}
