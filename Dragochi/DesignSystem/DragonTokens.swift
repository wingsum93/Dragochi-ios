//
//  DragonTokens.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DragonColorToken: CaseIterable {
    case bgBase
    case surfaceCard
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

enum DragonTypographyToken {
    case displayTimer
    case titleSection
    case labelSmall
    case body
    case cta

    var font: Font {
        switch self {
        case .displayTimer:
            return dragonFont(named: "BeVietnamPro-Bold", size: 60, weight: .bold, relativeTo: .largeTitle)
        case .titleSection:
            return dragonFont(named: "BeVietnamPro-SemiBold", size: 14, weight: .semibold, relativeTo: .headline)
        case .labelSmall:
            return dragonFont(named: "BeVietnamPro-Medium", size: 12, weight: .medium, relativeTo: .subheadline)
        case .body:
            return dragonFont(named: "BeVietnamPro-Regular", size: 14, weight: .regular, relativeTo: .body)
        case .cta:
            return dragonFont(named: "BeVietnamPro-Bold", size: 18, weight: .bold, relativeTo: .title3)
        }
    }
}

enum DragonRadiusToken {
    case bottomSheetTop
    case card
    case avatar
    case pill

    var value: CGFloat {
        switch self {
        case .bottomSheetTop:
            return 48
        case .card:
            return 32
        case .avatar, .pill:
            return 9999
        }
    }
}

enum DragonSpacingToken {
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl

    var value: CGFloat {
        switch self {
        case .xxs:
            return 4
        case .xs:
            return 8
        case .sm:
            return 12
        case .md:
            return 16
        case .lg:
            return 24
        case .xl:
            return 32
        case .xxl:
            return 48
        }
    }
}

struct DragonTheme {
    static let neonDark = DragonTheme()
    static let current = DragonTheme.neonDark

    func color(_ token: DragonColorToken) -> Color {
        token.color
    }

    func font(_ token: DragonTypographyToken) -> Font {
        token.font
    }

    func radius(_ token: DragonRadiusToken) -> CGFloat {
        token.value
    }

    func spacing(_ token: DragonSpacingToken) -> CGFloat {
        token.value
    }
}

private func dragonFont(named fontName: String, size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
#if canImport(UIKit)
    if UIFont(name: fontName, size: size) != nil {
        return .custom(fontName, size: size, relativeTo: textStyle)
    }
#endif
    return .system(size: size, weight: weight, design: .default)
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}
