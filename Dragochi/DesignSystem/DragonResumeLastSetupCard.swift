//
//  DragonResumeLastSetupCard.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonResumeLastSetupCard: View {
    let model: DragonResumeLastSetupModel
    let isResumeEnabled: Bool
    let onToggleResume: (Bool) -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            HStack {
                Text("title_resume_last_setup")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    .tracking(0.8)
                    .textCase(.uppercase)

                Spacer()

                Toggle("", isOn: resumeToggleBinding)
                    .labelsHidden()
                    .tint(DragonTheme.current.color(.accentPrimary))
                    .accessibilityIdentifier("toggle.resumeLastSetup")
            }

            Button(action: onTap) {
                HStack(spacing: DragonTheme.current.spacing(.sm)) {
                    gameArtwork

                    VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.xxs)) {
                        Text(model.gameTitle)
                            .font(DragonTheme.current.font(.titleSection))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            Text(model.platformLabel)
                            Text("•")
                            Text(model.teammatesLabel)
                        }
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textSecondary))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: DragonTheme.current.spacing(.xs))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
                .padding(DragonTheme.current.spacing(.sm))
                .background(DragonTheme.current.color(.bgBase).opacity(0.35))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: DragonTheme.current.radius(.card) - 8,
                        style: .continuous
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: DragonTheme.current.radius(.card) - 8,
                        style: .continuous
                    )
                    .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DragonTheme.current.spacing(.md))
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
        )
        .accessibilityIdentifier("card.resumeLastSetup")
    }

    private var resumeToggleBinding: Binding<Bool> {
        Binding(
            get: { isResumeEnabled },
            set: { isEnabled in onToggleResume(isEnabled) }
        )
    }

    @ViewBuilder
    private var gameArtwork: some View {
        Group {
            if let imageAssetName = model.gameImageAssetName {
                Image(imageAssetName)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackArtwork
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DragonTheme.current.color(.borderSoft), lineWidth: 1)
        )
    }

    private var fallbackArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DragonTheme.current.color(.accentPrimaryDim),
                    DragonTheme.current.color(.surfaceCard)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
        }
    }
}

#if DEBUG
#Preview("Resume Last Setup Card") {
    DragonResumeLastSetupCard(
        model: DragonResumeLastSetupModel(
            id: UUID(),
            gameTitle: "Valorant",
            gameImageAssetName: "volarant",
            platformLabel: "PC",
            teammatesLabel: "Mason, Ava"
        ),
        isResumeEnabled: true,
        onToggleResume: { _ in },
        onTap: {}
    )
    .padding(DragonTheme.current.spacing(.lg))
    .background(DragonTheme.current.color(.bgBase))
}
#endif
