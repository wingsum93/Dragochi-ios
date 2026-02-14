//
//  DragochiTests.swift
//  DragochiTests
//
//  Created by eric ho on 11/2/2026.
//

import Foundation
import Testing
@testable import Dragochi

struct DragochiTests {
    @Test
    func gameEntity_decodesLegacyIconField() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "name": "Legacy",
          "icon": "lol"
        }
        """

        let decoded = try JSONDecoder().decode(GameEntity.self, from: Data(json.utf8))
        #expect(decoded.id == id)
        #expect(decoded.name == "Legacy")
        #expect(decoded.imageAssetName == "lol")
    }
}
