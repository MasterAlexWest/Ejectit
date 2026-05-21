import SwiftUI

@main
struct EjectitApp: App {
    @StateObject private var driveManager = DriveManager()

    var body: some Scene {
        MenuBarExtra("Ejectit", systemImage: "eject.circle.fill") {
            MenuBarContentView()
                .environmentObject(driveManager)
        }
        .menuBarExtraStyle(.window)
    }
}
