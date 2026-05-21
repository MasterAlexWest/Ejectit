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
        includingResourceValuesForKeys: [
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeLocalizedNameKey
        ],
        options: .skipHiddenVolumes
    ) else { return [] }

    return urls.compactMap { url -> Volume? in
        guard let resources = try? url.resourceValues(forKeys: [
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeLocalizedNameKey
        ]) else { return nil }

        let isInternal = resources.volumeIsInternal ?? true
        let isRemovable = resources.volumeIsRemovable ?? false
        let isEjectable = resources.volumeIsEjectable ?? false

        guard !isInternal && (isRemovable || isEjectable) else { return nil }

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
