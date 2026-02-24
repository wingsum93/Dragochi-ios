//
//  Platform.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

enum Platform: String, CaseIterable, Codable, Hashable {
    case mobile
    case pc
    case console

    var titleKey: String {
        switch self {
        case .mobile:
            return "title_platform_mobile"
        case .pc:
            return "title_platform_pc"
        case .console:
            return "title_platform_console"
        }
    }
}
