import Foundation

/// One screen of the setup sheet. Raw values are what `onboardingStepName`
/// stores, so renaming a case strands saved progress.
enum OnboardingStep: String, CaseIterable {
    case welcome, permissions, meetCopilot, copilotPath, speechModel, copilotSetup, automatic, aiApps, ready
}

/// How Copilot runs, picked on "How should Copilot work?".
enum CopilotPath: String, CaseIterable {
    case `private`, balanced, cloud, later
    static let defaultsKey = "onboardingCopilotPath"
}

/// The full first-run tour, or the short "Set up Copilot" one from Home or
/// Settings.
enum OnboardingMode: String {
    case full, copilot
    static let defaultsKey = "onboardingMode"
}

enum OnboardingFlow {
    static let stepKey = "onboardingStepName"
    /// The old Int index (0 welcome … 4 ready), read once and removed.
    static let legacyStepKey = "onboardingStep"

    static func steps(mode: OnboardingMode, path: CopilotPath?) -> [OnboardingStep] {
        switch mode {
        case .copilot:
            let setup: [OnboardingStep] = (path == nil || path == .later) ? [] : [.copilotSetup]
            return [.meetCopilot, .copilotPath] + setup + [.ready]
        case .full:
            let middle: [OnboardingStep]
            switch path {
            case .private?, .balanced?: middle = [.speechModel, .copilotSetup]
            case .cloud?: middle = [.copilotSetup]
            case .later?, nil: middle = [.speechModel]
            }
            // Claude, Cursor and Codex send what they read to their company, so
            // someone who asked for nothing to leave the Mac isn't pitched it.
            let aiApps: [OnboardingStep] = path == .private ? [] : [.aiApps]
            return [.welcome, .permissions, .meetCopilot, .copilotPath] + middle + [.automatic] + aiApps + [.ready]
        }
    }

    /// The step `offset` away, clamped to the list.
    static func step(_ offset: Int, from step: OnboardingStep, in steps: [OnboardingStep]) -> OnboardingStep {
        guard let base = steps.firstIndex(of: resolve(step, in: steps)) else { return steps.first ?? step }
        let index = base + offset
        return steps[min(max(index, 0), steps.count - 1)]
    }

    /// A saved step that no longer belongs to the list (the path changed
    /// under it) lands on the path choice.
    static func resolve(_ step: OnboardingStep, in steps: [OnboardingStep]) -> OnboardingStep {
        if steps.contains(step) { return step }
        return steps.contains(.copilotPath) ? .copilotPath : steps[0]
    }

    /// Moves the old Int step to a name, once. Anyone past permissions lands
    /// on Meet Copilot, so nobody mid-tour during an update skips it.
    static func migrateLegacyStep(in defaults: UserDefaults) {
        guard defaults.string(forKey: stepKey) == nil,
              let old = defaults.object(forKey: legacyStepKey) as? Int else { return }
        let step: OnboardingStep = old <= 0 ? .welcome : old == 1 ? .permissions : .meetCopilot
        defaults.set(step.rawValue, forKey: stepKey)
        defaults.removeObject(forKey: legacyStepKey)
    }
}

/// Defaults that fit this Mac's memory.
enum MachineFit {
    static func memoryGB(_ bytes: UInt64 = ProcessInfo.processInfo.physicalMemory) -> Int {
        Int((Double(bytes) / 1_073_741_824).rounded())
    }

    // ponytail: one threshold for both models; split it if a 12 GB Mac
    // proves too tight for turbo plus gemma together.
    private static func isLarge(_ memoryGB: Int) -> Bool { memoryGB >= 12 }

    static func whisperModel(memoryGB: Int) -> String { isLarge(memoryGB) ? "large-v3-turbo" : "base" }

    /// What this Mac has, read once.
    struct Machine {
        var memoryGB: Int
        var cores: Int
        var appleSilicon: Bool
        var freeDiskGB: Double
        static func current() -> Machine {
            #if arch(arm64)
            let arm = true
            #else
            let arm = false
            #endif
            return Machine(memoryGB: MachineFit.memoryGB(),
                           cores: ProcessInfo.processInfo.activeProcessorCount,
                           appleSilicon: arm,
                           freeDiskGB: Double(MachineFit.freeDiskBytes() ?? 0) / 1_073_741_824)
        }
    }

    /// Free space on the volume that holds the models, in bytes.
    static func freeDiskBytes() -> Int64? {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    /// Approximate download size of a local model, in GB.
    static func downloadGB(_ model: String) -> Double {
        switch model {
        case "tiny": return 0.04
        case "base": return 0.14
        case "small": return 0.46
        case "large-v3-v20240930_626MB": return 0.63
        case "large-v3-turbo": return 1.6
        default: return model.lowercased().contains("parakeet") ? 0.5 : 1.6
        }
    }

    /// Whisper size for this machine, with the reason in plain Chinese.
    static func whisperModel(for m: Machine) -> (model: String, reason: String) {
        let spec = "\(m.appleSilicon ? "Apple 芯片" : "Intel 处理器")，\(m.cores) 核，内存 \(m.memoryGB) GB，可用磁盘 \(String(format: "%.1f", m.freeDiskGB)) GB"
        if m.freeDiskGB < 1 {
            return ("tiny", spec + "。磁盘空间紧张，选用最小的模型。")
        }
        if m.freeDiskGB < 3 {
            return ("base", spec + "。磁盘空间有限，选用体积较小的模型。")
        }
        if !m.appleSilicon {
            let model = m.memoryGB >= 16 && m.cores >= 8 ? "small" : "base"
            return (model, spec + "。Intel Mac 没有神经网络引擎，大模型会明显变慢，选用速度和准确度均衡的模型。")
        }
        if isLarge(m.memoryGB) {
            return ("large-v3-turbo", spec + "。内存充足，选用准确度最高的模型。")
        }
        return ("base", spec + "。内存较少，选用占用更低的模型，避免会议中卡顿。")
    }
    static func ollamaModel(memoryGB: Int) -> String { isLarge(memoryGB) ? "gemma3:4b" : "llama3.2:3b" }
}
