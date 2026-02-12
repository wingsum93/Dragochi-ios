//
//  SessionFriendRecord.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@Model
final class SessionFriendRecord {
    var id: UUID
    var session: SessionRecord?
    var friend: FriendRecord?

    init(
        id: UUID = UUID(),
        session: SessionRecord,
        friend: FriendRecord
    ) {
        self.id = id
        self.session = session
        self.friend = friend
    }
}

