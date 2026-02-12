//
//  DragonColor.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

enum DragonColor: CaseIterable {
    case bgBase
    case surfaceCard
    case tabTintShine
    case accentPrimary
    case accentPrimaryDim
    case accentPrimarySoft
    case textPrimary
    case textSecondary
    case textTertiary
    case textPlaceholder
    case borderSoft
    case borderNeon
    case overlayScrim

    var color: Color {
        switch self {
        case .bgBase:
            return Color(hex: 0x102216)
        case .surfaceCard:
            return Color(hex: 0x152E1E)
        case .tabTintShine:
            return Color(hex: 0x80FFCC)
        case .accentPrimary:
            return Color(hex: 0x13EC5B)
        case .accentPrimaryDim:
            return Color(red: 19 / 255, green: 236 / 255, blue: 91 / 255, opacity: 0.20)
        case .accentPrimarySoft:
            return Color(red: 19 / 255, green: 236 / 255, blue: 91 / 255, opacity: 0.10)
        case .textPrimary:
            return Color.white.opacity(0.90)
        case .textSecondary:
            return Color.white.opacity(0.60)
        case .textTertiary:
            return Color.white.opacity(0.40)
        case .textPlaceholder:
            return Color.white.opacity(0.20)
        case .borderSoft:
            return Color.white.opacity(0.10)
        case .borderNeon:
            return Color(red: 19 / 255, green: 236 / 255, blue: 91 / 255, opacity: 0.20)
        case .overlayScrim:
            return Color(red: 16 / 255, green: 34 / 255, blue: 22 / 255, opacity: 0.80)
        }
    }
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}
