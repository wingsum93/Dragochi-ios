//
//  DragonRadius.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

enum DragonRadius {
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

