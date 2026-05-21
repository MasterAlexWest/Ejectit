import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var driveManager: DriveManager
    @ObservedObject private var prefs = Preferences.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Ejectify")
                    .font(.headline)
                Spacer()
                Button("Eject All") {
                    Task { await driveManager.ejectAll() }
                }
                .disabled(driveManager.volumes.filter(\.isEnabled).isEmpty || driveManager.isEjecting)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Drive list
            if driveManager.volumes.isEmpty {
                Text("No external drives")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(driveManager.volumes) { volume in
                        DriveRowView(volume: volume)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            // Settings
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Eject on:")
                        .foregroundStyle(.secondary)
                    Picker("", selection: Binding(
                        get: { prefs.unmountWhenEnum },
                        set: { prefs.unmountWhenEnum = $0 }
                    )) {
                        ForEach(UnmountWhen.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Quit
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 260)
    }
}
