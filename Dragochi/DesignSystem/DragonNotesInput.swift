//
//  DragonNotesInput.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonNotesInput: View {
    @Binding var text: String
    let placeholder: String
    let actions: [NotesQuickAction]
    var onAction: ((NotesQuickAction) -> Void)?

    @FocusState private var isFocused: Bool

    private var state: NotesState {
        if isFocused { return .focused }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .filled
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96, maxHeight: 96)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                .font(DragonTheme.current.font(.body))
                .background(DragonTheme.current.color(.surfaceCard))
                .overlay(
                    RoundedRectangle(cornerRadius: DragonTheme.current.radius(.bottomSheetTop), style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: DragonTheme.current.radius(.bottomSheetTop), style: .continuous)
                )

            if text.isEmpty {
                Text(placeholder)
                    .font(DragonTheme.current.font(.body))
                    .foregroundStyle(DragonTheme.current.color(.textPlaceholder))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }

            HStack(spacing: 4) {
                ForEach(actions) { item in
                    Button {
                        onAction?(item)
                    } label: {
                        Image(systemName: item.iconName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            .frame(width: 22, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 10)
        }
    }

    private var borderColor: Color {
        switch state {
        case .focused:
            return DragonTheme.current.color(.borderNeon)
        case .idle, .filled:
            return .clear
        }
    }
}

private enum NotesState {
    case idle
    case focused
    case filled
}
