//
//  DragonSessionHero.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonSessionHero: View {
    let title: String
    let durationText: String?
    let trendText: String
    let trendDirection: TrendDirection

    var body: some View {
        VStack(spacing: DragonTheme.current.spacing(.xs)) {
            Text(title)
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textSecondary))
                .tracking(0.7)
                .textCase(.uppercase)

            if let durationText, !durationText.isEmpty {
                Text(durationText)
                    .font(DragonTheme.current.font(.displayTimer))
                    .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            HStack(spacing: DragonTheme.current.spacing(.xxs)) {
                Image(systemName: trendDirection.iconName)
                    .font(.system(size: 12, weight: .semibold))
                Text(trendText)
                    .font(DragonTheme.current.font(.labelSmall))
            }
            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DragonTheme.current.color(.accentPrimarySoft))
            .overlay(
                Capsule()
                    .stroke(DragonTheme.current.color(.borderNeon), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}
