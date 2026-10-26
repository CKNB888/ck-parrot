import Foundation

/// ck-parrot v2.1.1: the menu-bar panel's provider / model switch. Writes the
/// same UserDefaults keys Settings uses; providers resolve them fresh on every
/// request, so the next call uses the new choice and it survives relaunch.
enum PanelModelSwitch {
    static let customHistoryKey = "copilotCustomModelHistory"

    static func setProvider(_ kind: CopilotProviderKind, defaults: UserDefaults = .standard) {
        defaults.set(kind.rawValue, forKey: "copilotProvider")
    }

    /// Models offered as one-click chips for a provider.
    static func models(for kind: CopilotProviderKind, defaults: UserDefaults = .standard) -> [String] {
        switch kind {
        case .claude: return [ClaudeAnalysisProvider.model]
        case .ollama:
            let current = defaults.string(forKey: "copilotOllamaModel")?.nilIfEmpty
            return unique([current].compactMap { $0 } + OllamaCatalog.ids)
        case .custom:
            let current = defaults.string(forKey: "copilotCustomModel")?.nilIfEmpty
            return unique([current].compactMap { $0 } + (defaults.stringArray(forKey: customHistoryKey) ?? []))
        }
    }

    static func currentModel(for kind: CopilotProviderKind, defaults: UserDefaults = .standard) -> String {
        switch kind {
        case .claude: return ClaudeAnalysisProvider.model
        case .ollama: return defaults.string(forKey: "copilotOllamaModel")?.nilIfEmpty ?? "llama3.2:3b"
        case .custom: return defaults.string(forKey: "copilotCustomModel") ?? ""
        }
    }

    /// Returns false when the provider has a fixed model (Claude) or the name is empty.
    @discardableResult
    static func setModel(_ raw: String, for kind: CopilotProviderKind, defaults: UserDefaults = .standard) -> Bool {
        let model = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else { return false }
        switch kind {
        case .claude: return false
        case .ollama: defaults.set(model, forKey: "copilotOllamaModel")
        case .custom:
            defaults.set(model, forKey: "copilotCustomModel")
            let history = unique([model] + (defaults.stringArray(forKey: customHistoryKey) ?? []))
            defaults.set(Array(history.prefix(8)), forKey: customHistoryKey)
        }
        return true
    }

    static func setTranscription(_ backend: TranscriptionBackend, defaults: UserDefaults = .standard) {
        defaults.set(backend.rawValue, forKey: TranscriptionBackend.defaultsKey)
    }

    private static func unique(_ xs: [String]) -> [String] {
        var seen = Set<String>()
        return xs.filter { seen.insert($0).inserted }
    }
}
