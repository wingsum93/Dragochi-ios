//
//  DragochiApp.swift
//  Dragochi
//
//  Created by eric ho on 11/2/2026.
//

import SwiftUI
import SwiftData
import UIKit
import FirebaseCore

@main
struct DragochiApp: App {
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        configureFirebaseIfPossible()
    }

    var sharedModelContainer: ModelContainer = {
        do {
            let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            return try SwiftDataStack.makeContainer(inMemory: isRunningTests)
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

    private func configureFirebaseIfPossible() {
        guard !isRunningTests else { return }
        guard FirebaseApp.app() == nil else { return }
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            return
        }
        FirebaseApp.configure(options: options)
    }
}
