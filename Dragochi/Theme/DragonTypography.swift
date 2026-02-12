//
//  DragonTypography.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DragonTypography {
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

private func dragonFont(
    named fontName: String,
    size: CGFloat,
    weight: Font.Weight,
    relativeTo textStyle: Font.TextStyle
) -> Font {
#if canImport(UIKit)
    if UIFont(name: fontName, size: size) != nil {
        return .custom(fontName, size: size, relativeTo: textStyle)
    }
#endif
    return .system(size: size, weight: weight, design: .default)
}

