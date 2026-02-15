//
//  EnabledGameSelectionRecord.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation
import SwiftData

@Model
final class EnabledGameSelectionRecord {
    @Attribute(.unique) var remoteID: String

    init(remoteID: String) {
        self.remoteID = remoteID
    }
}
