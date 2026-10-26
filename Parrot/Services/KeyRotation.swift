import Foundation

/// ck-parrot v2.1.1: several API keys per provider (e.g. multiple Groq keys).
/// The keychain item holds the keys separated by newlines, commas or spaces.
/// On 401/402/403/429 the failing key rests for a while and the next key is tried.
/// Keys are never logged.
enum KeyRotation {
    static let rotateStatus: Set<Int> = [401, 402, 403, 429]
    static let roundRobinKey = "keyRoundRobin"

    private static let lock = NSLock()
    private static var restUntil: [String: Date] = [:]
    private static var cursor: [String: Int] = [:]

    static func split(_ raw: String?) -> [String] {
        guard let raw else { return [] }
        var seen = Set<String>()
        return raw.components(separatedBy: CharacterSet(charactersIn: ",; \t\r\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    static func join(_ keys: [String]) -> String { keys.joined(separator: "\n") }

    static func mask(_ key: String) -> String {
        let tail = key.count > 4 ? String(key.suffix(4)) : ""
        let head = key.hasPrefix("gsk_") ? "gsk_" : (key.hasPrefix("sk-") ? "sk-" : "")
        return "\(head)****\(tail)"
    }

    static var roundRobin: Bool { UserDefaults.standard.bool(forKey: roundRobinKey) }

    /// Seconds a key rests after a failure.
    static func cooldown(status: Int, retryAfter: String?) -> TimeInterval {
        switch status {
        case 429:
            let ra = retryAfter.flatMap { TimeInterval($0.trimmingCharacters(in: .whitespaces)) } ?? 60
            return min(max(ra, 20), 15 * 60)
        case 402: return 30 * 60
        default: return 10 * 60
        }
    }

    /// Keys in the order to try: ready keys first (rotated when round-robin is on),
    /// then resting keys, soonest-to-recover first.
    static func order(scope: String, keys: [String], now: Date = Date()) -> [String] {
        lock.lock(); defer { lock.unlock() }
        var ready = keys.filter { (restUntil["\(scope)|\($0)"] ?? .distantPast) <= now }
        let resting = keys.filter { (restUntil["\(scope)|\($0)"] ?? .distantPast) > now }
            .sorted { restUntil["\(scope)|\($0)"]! < restUntil["\(scope)|\($1)"]! }
        if roundRobin, ready.count > 1 {
            let c = (cursor[scope] ?? 0) % ready.count
            cursor[scope] = c + 1
            ready = Array(ready[c...] + ready[..<c])
        }
        return ready + resting
    }

    static func markFailure(scope: String, key: String, status: Int, retryAfter: String?, now: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        restUntil["\(scope)|\(key)"] = now.addingTimeInterval(cooldown(status: status, retryAfter: retryAfter))
    }

    static func isResting(scope: String, key: String, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return (restUntil["\(scope)|\(key)"] ?? .distantPast) > now
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        restUntil = [:]; cursor = [:]
    }
}
