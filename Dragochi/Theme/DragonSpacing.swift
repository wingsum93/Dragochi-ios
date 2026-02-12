//
//  DragonSpacing.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

enum DragonSpacing {
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

