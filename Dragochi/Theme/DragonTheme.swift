//
//  DragonTheme.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct DragonTheme {
    static let neonDark = DragonTheme()
    static let current = DragonTheme.neonDark

    func color(_ token: DragonColor) -> Color {
        token.color
    }

    func font(_ token: DragonTypography) -> Font {
        token.font
    }

    func radius(_ token: DragonRadius) -> CGFloat {
        token.value
    }

    func spacing(_ token: DragonSpacing) -> CGFloat {
        token.value
    }
}

