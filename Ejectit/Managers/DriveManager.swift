import AppKit
import Combine

@MainActor
class DriveManager: ObservableObject {
    @Published var volumes: [Volume] = []
    @Published var isEjecting: Bool = false

    private var ejectedBSDNames: [String] = []
    private let sleepWatcher = SleepWatcher()
    private var observers: [NSObjectProtocol] = []

    init() {
        refreshVolumes()
        startWorkspaceObservers()
        startSleepTask()
    }

    deinit {
        for obs in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    // MARK: - Volume discovery

    func refreshVolumes() {
        let fresh = mountedExternalVolumes()
        // Preserve in-memory isEnabled state if already loaded
        volumes = fresh.map { vol in
            if let existing = volumes.first(where: { $0.id == vol.id }) {
                var v = vol
                v.isEnabled = existing.isEnabled
                return v
            }
            return vol
        }
    }

    func setEnabled(_ enabled: Bool, for volume: Volume) {
        guard let idx = volumes.firstIndex(where: { $0.id == volume.id }) else { return }
        volumes[idx].isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "enabled.\(volume.deviceBSDName)")
    }

    // MARK: - Eject

    func ejectAll() async {
        let targets = volumes.filter(\.isEnabled)
        guard !targets.isEmpty else { return }
        isEjecting = true
        defer { isEjecting = false }
        ejectedBSDNames = targets.map(\.deviceBSDName)
        await withTaskGroup(of: Void.self) { group in
            for vol in targets {
                group.addTask { await self.eject(vol) }
            }
        }
    }

    func eject(_ volume: Volume) async {
        // Try a polite unmount first; fall back to `force` if a process (e.g. loginwindow
        // holding a Spotlight/recent-files handle) dissents. Skip the polite attempt when
        // the user has explicitly opted into forceUnmount.
        if !Preferences.shared.forceUnmount {
            if await runDiskUtil(["unmount", volume.url.path]) { return }
        }
        _ = await runDiskUtil(["unmount", "force", volume.url.path])
    }

    // MARK: - Remount

    private func remountEjected() async {
        let bsds = ejectedBSDNames
        ejectedBSDNames = []
        for bsd in bsds {
            var attempt = 0
            while attempt < 3 {
                let success = await runDiskUtil(["mount", bsd])
                if success { break }
                attempt += 1
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    private func runDiskUtil(_ args: [String]) async -> Bool {
        await withCheckedContinuation { cont in
            DispatchQueue.global().async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
                proc.arguments = args
                do {
                    try proc.run()
                    proc.waitUntilExit()
                    cont.resume(returning: proc.terminationStatus == 0)
                } catch {
                    cont.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Sleep handling

    private func startSleepTask() {
        Task {
            for await event in sleepWatcher.events {
                await handleSleepEvent(event)
            }
        }
    }

    private func handleSleepEvent(_ event: SleepEvent) async {
        let prefs = Preferences.shared
        if prefs.unmountWhenEnum.matches(event) {
            await ejectAll()
        } else if prefs.unmountWhenEnum.matchesWake(event) {
            await remountEjected()
        }
    }

    // MARK: - Workspace notifications

    private func startWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        observers.append(nc.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor [weak self] in self?.refreshVolumes() } })

        observers.append(nc.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor [weak self] in self?.refreshVolumes() } })
    }
}
