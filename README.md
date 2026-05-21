# Ejectit

A macOS menu bar app that automatically unmounts external drives before the system or display sleeps, and remounts them on wake — so you stop seeing *"Disk Not Ejected Properly"* notifications.

## Features

- **Auto-unmount on sleep** — choose between system sleep, display sleep, or both
- **Auto-remount on wake** — drives that were unmounted are brought back automatically
- **Per-drive toggle** — exclude specific drives from auto-ejection
- **Manual eject** — eject all enabled drives, or one at a time
- **Polite-then-force fallback** — if a process (e.g. `loginwindow`) holds a handle, the app retries with `unmount force`
- **Launch at Login** — optional, via `SMAppService`
- **No Dock icon** — runs as a menu bar utility (`LSUIElement`)

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build)

## Build & Run

1. Open `Ejectit.xcodeproj` in Xcode
2. Build & Run (Cmd+R)
3. The first time it touches a removable volume, macOS will prompt for access — click *Allow*

## Usage

Click the eject icon in the menu bar to open the panel:

- **Eject All** — unmount every drive whose toggle is on
- **Per-drive switch** — enable/disable that drive for auto-ejection
- **Per-drive eject button** — eject just that one drive
- **Eject on:** — choose the trigger (System Sleep, Display Sleep, or Either)
- **Launch at Login** — start automatically on login

## Prior art

Ejectit takes its architectural cues from [nielsmouthaan/ejectify-macos](https://github.com/nielsmouthaan/ejectify-macos) — a feature-rich Swift/AppKit menu bar app with a privileged helper, IOKit power notifications, and Disk Arbitration. Ejectit is a leaner SwiftUI take on the same idea, using `MenuBarExtra` for the UI and `diskutil` + `NSWorkspace`/IOKit notifications for the actual work.
