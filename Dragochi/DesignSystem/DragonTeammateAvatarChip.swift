//
//  DragonTeammateAvatarChip.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonTeammateAvatarChip: View {
    let model: TeammateChipModel
    let state: SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    avatar

                    if state == .selected {
                        Circle()
                            .fill(DragonTheme.current.color(.accentPrimary))
                            .frame(width: 16, height: 16)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                            .offset(x: 2, y: 2)
                    }
                }

                Text(state == .add ? "Add" : model.name)
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
        .opacity(state == .unselected ? 0.55 : 1)
    }

    @ViewBuilder
    private var avatar: some View {
        switch state {
        case .add:
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
        case .selected, .unselected:
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                DragonTheme.current.color(.accentPrimary),
                                DragonTheme.current.color(.accentPrimary).opacity(0),
                                DragonTheme.current.color(.accentPrimary)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(state == .selected ? 1 : 0)

                avatarImage
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(DragonTheme.current.color(.bgBase), lineWidth: 2)
                }
            }
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let avatarAssetName = model.avatarAssetName {
            Image(avatarAssetName)
                .resizable()
                .scaledToFill()
        } else if let avatarURL = model.avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(DragonTheme.current.color(.surfaceCard))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
    }

    private var labelColor: Color {
        switch state {
        case .selected:
            return .white
        case .unselected, .add:
            return DragonTheme.current.color(.textTertiary)
        }
    }
}
