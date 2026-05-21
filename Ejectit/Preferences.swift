import ServiceManagement
import SwiftUI

enum UnmountWhen: String, CaseIterable {
    case systemSleeps = "System Sleep"
    case displaySleeps = "Display Sleep"
    case both = "Either"

    func matches(_ event: SleepEvent) -> Bool {
        switch self {
        case .systemSleeps:  return event == .systemWillSleep
        case .displaySleeps: return event == .screenDidSleep
        case .both:          return event == .systemWillSleep || event == .screenDidSleep
        }
    }

    func matchesWake(_ event: SleepEvent) -> Bool {
        switch self {
        case .systemSleeps:  return event == .systemDidWake
        case .displaySleeps: return event == .screenDidWake
        case .both:          return event == .systemDidWake || event == .screenDidWake
        }
    }
}

class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("unmountWhen") var unmountWhen: String = UnmountWhen.systemSleeps.rawValue
    @AppStorage("forceUnmount") var forceUnmount: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { updateLoginItem() }
    }

    var unmountWhenEnum: UnmountWhen {
        get { UnmountWhen(rawValue: unmountWhen) ?? .systemSleeps }
        set { unmountWhen = newValue.rawValue }
    }

    private func updateLoginItem() {
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
