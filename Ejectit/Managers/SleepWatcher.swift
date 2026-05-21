import Cocoa
import IOKit.pwr_mgt

enum SleepEvent {
    case systemWillSleep
    case systemDidWake
    case screenDidSleep
    case screenDidWake
}

// File-level free function required — Swift cannot use capturing closures as C function pointers.
private func ioKitPowerCallback(
    _ context: UnsafeMutableRawPointer?,
    _ service: io_service_t,
    _ messageType: UInt32,
    _ messageArgument: UnsafeMutableRawPointer?
) {
    guard let ctx = context else { return }
    let watcher = Unmanaged<SleepWatcher>.fromOpaque(ctx).takeUnretainedValue()
    // kIOMessageSystemWillSleep / kIOMessageSystemHasPoweredOn are C macros not bridged to Swift.
    switch messageType {
    case 0xe0000280: // kIOMessageSystemWillSleep
        watcher.continuation?.yield(.systemWillSleep)
        IOAllowPowerChange(watcher.rootPort, Int(bitPattern: messageArgument))
    case 0xe0000300: // kIOMessageSystemHasPoweredOn
        watcher.continuation?.yield(.systemDidWake)
    default:
        IOAllowPowerChange(watcher.rootPort, Int(bitPattern: messageArgument))
    }
}

final class SleepWatcher {
    fileprivate var continuation: AsyncStream<SleepEvent>.Continuation?
    private var notifyPort: IONotificationPortRef?
    private var notifier: io_object_t = 0
    private var observers: [NSObjectProtocol] = []

    let events: AsyncStream<SleepEvent>

    init() {
        var cont: AsyncStream<SleepEvent>.Continuation!
        events = AsyncStream { cont = $0 }
        continuation = cont
        startIOKit()
        startWorkspaceObservers()
    }

    deinit {
        if notifier != 0 { IODeregisterForSystemPower(&notifier) }
        if let port = notifyPort { IONotificationPortDestroy(port) }
        for obs in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    private func startIOKit() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        rootPort = IORegisterForSystemPower(context, &notifyPort, ioKitPowerCallback, &notifier)
        if let port = notifyPort {
            CFRunLoopAddSource(
                CFRunLoopGetMain(),
                IONotificationPortGetRunLoopSource(port).takeUnretainedValue(),
                .defaultMode
            )
        }
    }

    var rootPort: io_connect_t = 0

    private func startWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        observers.append(nc.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.continuation?.yield(.screenDidSleep) })

        observers.append(nc.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.continuation?.yield(.screenDidWake) })
    }
}
