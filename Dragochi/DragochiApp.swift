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
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

@main
struct DragochiApp: App {
    private let isRunningTests: Bool = {
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["XCTestConfigurationFilePath"] != nil
            || processInfo.arguments.contains("-ui-testing")
    }()

    init() {
        configureFirebaseIfPossible()
    }

    var sharedModelContainer: ModelContainer = {
        do {
            let processInfo = ProcessInfo.processInfo
            let isRunningTests = processInfo.environment["XCTestConfigurationFilePath"] != nil
                || processInfo.arguments.contains("-ui-testing")
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
        if FirebaseApp.app() == nil {
            guard
                let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                let options = FirebaseOptions(contentsOfFile: path)
            else {
                return
            }
            FirebaseApp.configure(options: options)
        }
#if canImport(FirebaseCrashlytics)
        if FirebaseApp.app() != nil {
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        }
#endif
    }
}
