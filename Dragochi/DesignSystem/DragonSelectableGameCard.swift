//
//  DragonSelectableGameCard.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonSelectableGameCard: View {
    let model: GameCardModel
    let state: SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 80, height: 112)
                    .overlay {
                        gameContent
                    }

                if state != .add {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                    .frame(width: 80, height: 112)

                    Text(model.title)
                        .font(DragonTheme.current.font(.gameCardLabel))
                        .foregroundStyle(.white)
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if state == .selected {
                    Circle()
                        .fill(DragonTheme.current.color(.accentPrimary))
                        .frame(width: 16, height: 16)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .shadow(color: glowColor, radius: 12)
            .opacity(opacityValue)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var gameContent: some View {
        switch state {
        case .add:
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
        case .selected, .unselected:
            Group {
                if let imageAssetName = model.imageAssetName {
                    Image(imageAssetName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [
                            DragonTheme.current.color(.surfaceCard),
                            DragonTheme.current.color(.bgBase)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 78, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card) - 2, style: .continuous))
        }
    }

    private var borderColor: Color {
        switch state {
        case .selected:
            return DragonTheme.current.color(.accentPrimary)
        case .unselected:
            return DragonTheme.current.color(.borderSoft)
        case .add:
            return DragonTheme.current.color(.borderSoft)
        }
    }

    private var borderWidth: CGFloat {
        state == .selected ? 2 : 1
    }

    private var glowColor: Color {
        state == .selected ? DragonTheme.current.color(.accentPrimary).opacity(0.3) : .clear
    }

    private var opacityValue: Double {
        state == .unselected ? 0.62 : 1
    }
}
