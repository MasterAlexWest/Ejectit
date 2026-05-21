import SwiftUI

struct DriveRowView: View {
    let volume: Volume
    @EnvironmentObject private var driveManager: DriveManager
    @State private var isEjectingThis = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "externaldrive")
                .foregroundStyle(.secondary)

            Text(volume.name)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Toggle("", isOn: Binding(
                get: { volume.isEnabled },
                set: { driveManager.setEnabled($0, for: volume) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            Button {
                isEjectingThis = true
                Task {
                    await driveManager.eject(volume)
                    isEjectingThis = false
                }
            } label: {
                Image(systemName: "eject")
            }
            .buttonStyle(.plain)
            .disabled(isEjectingThis)
        }
        .padding(.vertical, 2)
    }
}
