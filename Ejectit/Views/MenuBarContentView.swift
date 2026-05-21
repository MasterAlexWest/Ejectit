import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var driveManager: DriveManager
    @ObservedObject private var prefs = Preferences.shared
    @State private var ejectOnHover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Ejectit")
                    .font(.headline)
                Spacer()
                Button("Eject All") {
                    Task { await driveManager.ejectAll() }
                }
                .buttonStyle(LightPillButtonStyle())
                .disabled(driveManager.volumes.filter(\.isEnabled).isEmpty || driveManager.isEjecting)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)

            Divider()

            // Drive list
            Group {
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
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            // Settings
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Eject on:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        ForEach(UnmountWhen.allCases, id: \.self) { option in
                            Button(option.rawValue) { prefs.unmountWhenEnum = option }
                        }
                    } label: {
                        Text(prefs.unmountWhenEnum.rawValue)
                            .foregroundStyle(.primary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(ejectOnHover ? 0.18 : 0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .onHover { ejectOnHover = $0 }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)

            Divider()

            // Footer
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
                    .padding(.horizontal, 13)
                    .padding(.top, 12)
                    .padding(.bottom, 2)


                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuItemButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .frame(width: 260)
    }
}

struct LightPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LightPillButtonBody(configuration: configuration)
    }
}

struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuItemButtonBody(configuration: configuration)
    }
}

private struct MenuItemButtonBody: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .foregroundStyle(isHovering ? Color.white : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isHovering ? Color(nsColor: .controlAccentColor).opacity(0.72) : Color.clear)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .padding(.horizontal, 5)
    }
}

private struct LightPillButtonBody: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .onHover { isHovering = $0 }
    }

    private var fill: Color {
        // `Color.primary.opacity(...)` auto-adapts to light/dark.
        if configuration.isPressed { return Color.primary.opacity(0.18) }
        if isHovering              { return Color.primary.opacity(0.18) }
        return                              Color.primary.opacity(0.06)
    }
}

#Preview("With drives") {
    let manager = DriveManager()
    manager.volumes = [
        Volume(id: "disk5s1", url: URL(fileURLWithPath: "/Volumes/WORK"),  name: "WORK",  deviceBSDName: "disk5s1", isEnabled: true),
        Volume(id: "disk6s1", url: URL(fileURLWithPath: "/Volumes/MEDIA"), name: "MEDIA", deviceBSDName: "disk6s1", isEnabled: false)
    ]
    return MenuBarContentView().environmentObject(manager)
}

#Preview("Empty") {
    let manager = DriveManager()
    manager.volumes = []
    return MenuBarContentView().environmentObject(manager)
}
