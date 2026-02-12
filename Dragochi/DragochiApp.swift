//
//  DragochiApp.swift
//  Dragochi
//
//  Created by eric ho on 11/2/2026.
//

import SwiftUI
import SwiftData

@main
struct DragochiApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SwiftDataStack.makeContainer(inMemory: false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: sharedModelContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}
