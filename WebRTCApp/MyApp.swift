import SwiftUI

@main
struct WebRTCApp: App {
    private var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.arguments.contains("-XCTest")
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                ContentView()
            }
        }
    }
}
