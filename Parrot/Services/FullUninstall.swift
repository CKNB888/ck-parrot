import AppKit
import Foundation
import Security
import ServiceManagement

/// Settings → 完全卸载. Removes everything this app wrote, then moves the app
/// to the Trash and quits. Only paths named after this app's bundle id (or
/// its own folders inside its sandbox container) are touched.
enum FullUninstall {
    static let bundleID = "io.github.cknb6.ckparrot"

    /// Every location removed, relative to the user's (container) home.
    /// Under the App Sandbox the home is ~/Library/Containers/<bundle id>/Data.
    static func targets(home: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)) -> [URL] {
        let lib = home.appendingPathComponent("Library", isDirectory: true)
        let support = lib.appendingPathComponent("Application Support", isDirectory: true)
        return [
            support.appendingPathComponent("Parrot", isDirectory: true),          // audio, knowledge base, inbox
            support.appendingPathComponent("FluidAudio", isDirectory: true),      // Parakeet / VAD models
            support.appendingPathComponent(bundleID, isDirectory: true),
            support.appendingPathComponent("default.store"),                      // SwiftData
            support.appendingPathComponent("default.store-shm"),
            support.appendingPathComponent("default.store-wal"),
            home.appendingPathComponent("Documents/huggingface", isDirectory: true), // Whisper models
            lib.appendingPathComponent("Caches/\(bundleID)", isDirectory: true),
            lib.appendingPathComponent("HTTPStorages/\(bundleID)", isDirectory: true),
            lib.appendingPathComponent("WebKit/\(bundleID)", isDirectory: true),
            lib.appendingPathComponent("Logs/\(bundleID)", isDirectory: true),
            lib.appendingPathComponent("Saved Application State/\(bundleID).savedState", isDirectory: true),
            lib.appendingPathComponent("Preferences/\(bundleID).plist"),
        ]
    }

    /// Keychain accounts this app writes (service = bundle id).
    static func deleteKeychainItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: bundleID,
        ]
        // SecItemDelete removes all matches on macOS; loop until none remain.
        for _ in 0..<32 where SecItemDelete(query as CFDictionary) == errSecSuccess {}
    }

    @MainActor
    static func run() {
        try? SMAppService.mainApp.unregister()
        deleteKeychainItems()
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        let fm = FileManager.default
        for url in targets() where fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
        let app = Bundle.main.bundleURL
        NSWorkspace.shared.recycle([app]) { _, error in
            DispatchQueue.main.async {
                if error != nil { NSWorkspace.shared.activateFileViewerSelecting([app]) }
                NSApp.terminate(nil)
            }
        }
    }

    @MainActor
    static func confirmAndRun() {
        let alert = NSAlert()
        alert.messageText = "完全卸载 CK Parrot"
        alert.informativeText = "将删除全部会议记录、录音、已下载的语音模型、设置、缓存、钥匙串中的 API Key 和登录项，然后把应用移到废纸篓并退出。此操作无法撤销。"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "完全卸载")
        alert.addButton(withTitle: "取消")
        alert.buttons.first?.hasDestructiveAction = true
        if alert.runModal() == .alertFirstButtonReturn { run() }
    }
}
