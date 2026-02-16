//
//  DragonComponentStates.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

enum SelectionState {
    case selected
    case unselected
    case add
}

enum ControlState {
    case enabled
    case pressed
    case disabled
    case loading
}

enum TrendDirection {
    case up
    case down
    case neutral

    var iconName: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .neutral:
            return "minus"
        }
    }
}
