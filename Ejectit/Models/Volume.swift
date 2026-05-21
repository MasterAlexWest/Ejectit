import Foundation
import DiskArbitration

struct Volume: Identifiable, Hashable {
    let id: String           // BSD name e.g. "disk4s1" — stable across remounts
    let url: URL
    let name: String
    let deviceBSDName: String
    var isEnabled: Bool
}

func mountedExternalVolumes() -> [Volume] {
    guard let urls = FileManager.default.mountedVolumeURLs(
        includingResourceValuesForKeys: [.volumeIsInternalKey, .volumeLocalizedNameKey],
        options: .skipHiddenVolumes
    ) else { return [] }

    return urls.compactMap { url -> Volume? in
        guard let resources = try? url.resourceValues(forKeys: [
            .volumeIsInternalKey,
            .volumeLocalizedNameKey
        ]) else { return nil }

        // Default to non-internal when the key is unreadable — better to show an extra
        // drive than silently miss one. BSD name presence is the real gate: if DiskArbitration
        // can resolve a BSD name the OS considers it a manageable block device.
        let isInternal = resources.volumeIsInternal ?? false

        guard !isInternal else { return nil }

        let name = resources.volumeLocalizedName ?? url.lastPathComponent
        guard let bsd = bsdName(for: url) else { return nil }

        let enabled = UserDefaults.standard.object(forKey: "enabled.\(bsd)") as? Bool ?? true
        return Volume(id: bsd, url: url, name: name, deviceBSDName: bsd, isEnabled: enabled)
    }
}

func bsdName(for url: URL) -> String? {
    guard let session = DASessionCreate(kCFAllocatorDefault),
          let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL),
          let desc = DADiskCopyDescription(disk) as? [CFString: Any],
          let bsd = desc[kDADiskDescriptionMediaBSDNameKey] as? String
    else { return nil }
    return bsd
}
