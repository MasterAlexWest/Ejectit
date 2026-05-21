import SwiftUI

@main
struct EjectifyApp: App {
    @StateObject private var driveManager = DriveManager()

    var body: some Scene {
        MenuBarExtra("Ejectify", systemImage: "eject.circle.fill") {
            MenuBarContentView()
                .environmentObject(driveManager)
        }
        .menuBarExtraStyle(.window)
    }
}
