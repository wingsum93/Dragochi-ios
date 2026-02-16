//
//  DragonTextButton.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonTextButton: View {
    let title: String
    let state: ControlState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DragonTheme.current.font(.body))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .loading)
    }

    private var textColor: Color {
        switch state {
        case .enabled:
            return DragonTheme.current.color(.textTertiary)
        case .pressed:
            return DragonTheme.current.color(.textSecondary)
        case .disabled, .loading:
            return DragonTheme.current.color(.textTertiary).opacity(0.5)
        }
    }
}
