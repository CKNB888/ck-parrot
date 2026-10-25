import Foundation
import NaturalLanguage

/// Which on-device model a new install starts on. Parakeet when every
/// language this person uses is one of its 25; otherwise the Whisper that
/// fits the Mac's memory, because Parakeet can't transcribe the rest.
enum EngineRecommendation {
    static func recommend(preferredLanguages: [String], pastCallLanguages: [String], memoryGB: Int) -> String {
        let codes = preferredLanguages.map { Locale.Language(identifier: $0).languageCode?.identifier ?? $0 }
            + pastCallLanguages
        guard !codes.isEmpty, codes.allSatisfy(LanguageRouter.parakeetLanguages.contains) else {
            return MachineFit.whisperModel(memoryGB: memoryGB)
        }
        return ParakeetTranscriber.modelID
    }

    /// Same choice, for the whole machine (CPU, memory, disk), with a reason.
    static func recommend(preferredLanguages: [String], pastCallLanguages: [String],
                          machine: MachineFit.Machine) -> (model: String, reason: String) {
        let codes = preferredLanguages.map { Locale.Language(identifier: $0).languageCode?.identifier ?? $0 }
            + pastCallLanguages
        let whisper = MachineFit.whisperModel(for: machine)
        guard !codes.isEmpty, codes.allSatisfy(LanguageRouter.parakeetLanguages.contains),
              machine.appleSilicon, machine.freeDiskGB >= 3 else { return whisper }
        return (ParakeetTranscriber.modelID, "常用语言都在 Parakeet 支持范围内，Apple 芯片上速度最快。")
    }

    /// The main language of each saved transcript text, read on this Mac.
    static func pastCallLanguages(_ texts: [String]) -> [String] {
        texts.compactMap { text in
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(String(text.prefix(2000)))
            return recognizer.dominantLanguage?.rawValue
        }
    }
}
