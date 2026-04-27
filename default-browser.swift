import Cocoa
import Foundation

let probeURL = URL(string: "https://example.com")!

func displayName(for appURL: URL) -> String {
    if let bundle = Bundle(url: appURL),
       let name = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String
        ?? bundle.localizedInfoDictionary?["CFBundleName"] as? String
        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
        ?? bundle.infoDictionary?["CFBundleName"] as? String {
        return name
    }
    return FileManager.default.displayName(atPath: appURL.path)
}

func currentDefaultBundleID() -> String? {
    guard let url = NSWorkspace.shared.urlForApplication(toOpen: probeURL) else { return nil }
    return Bundle(url: url)?.bundleIdentifier
}

func listBrowsers() {
    let apps = NSWorkspace.shared.urlsForApplications(toOpen: probeURL)
    let currentID = currentDefaultBundleID()

    var seen = Set<String>()
    var items: [[String: Any]] = []

    for appURL in apps {
        guard let bundleID = Bundle(url: appURL)?.bundleIdentifier,
              !seen.contains(bundleID) else { continue }
        seen.insert(bundleID)

        let name = displayName(for: appURL)
        let isCurrent = bundleID == currentID
        let subtitle = isCurrent ? "✓ Current default — \(bundleID)" : bundleID

        items.append([
            "uid": bundleID,
            "title": name,
            "subtitle": subtitle,
            "arg": bundleID,
            "match": "\(name) \(bundleID)",
            "icon": ["type": "fileicon", "path": appURL.path],
        ])
    }

    items.sort { a, b in
        let aCur = (a["uid"] as? String) == currentID
        let bCur = (b["uid"] as? String) == currentID
        if aCur != bCur { return aCur }
        return ((a["title"] as? String) ?? "") < ((b["title"] as? String) ?? "")
    }

    let payload: [String: Any] = ["items": items]
    let data = try! JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
    FileHandle.standardOutput.write(data)
}

func setBrowser(bundleID: String) {
    guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
        FileHandle.standardError.write(Data("App not found for bundle id: \(bundleID)\n".utf8))
        exit(1)
    }

    let group = DispatchGroup()
    var firstError: Error?
    let lock = NSLock()

    for scheme in ["http", "https"] {
        group.enter()
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { error in
            if let error {
                lock.lock(); if firstError == nil { firstError = error }; lock.unlock()
            }
            group.leave()
        }
    }
    group.wait()

    if let firstError {
        FileHandle.standardError.write(Data("Error: \(firstError.localizedDescription)\n".utf8))
        exit(1)
    }

    print("Default browser set to \(displayName(for: appURL))")
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("Usage: default-browser list | set <bundle-id>\n".utf8))
    exit(1)
}

switch args[1] {
case "list":
    listBrowsers()
case "set":
    guard args.count >= 3 else {
        FileHandle.standardError.write(Data("Usage: default-browser set <bundle-id>\n".utf8))
        exit(1)
    }
    setBrowser(bundleID: args[2])
default:
    FileHandle.standardError.write(Data("Unknown command: \(args[1])\n".utf8))
    exit(1)
}
