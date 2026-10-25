import AVFoundation
import Foundation

/// v2.0: the user's own voiceprint, recorded once (about 15 s) and kept only
/// on this Mac (Application Support/Parrot/voiceprint.json, removed by
/// 完全卸载 with the rest of that folder). Diarization uses it to relabel any
/// system-audio cluster that is really the user (their voice coming back
/// through the speakers, or a shared room) as "Me", so it is never treated as
/// the other side and never triggers a suggested answer.
enum MyVoiceprint {
    /// FluidAudio embeddings, measured on real calls (see SpeakerProfileStore):
    /// same voice re-captured through speakers 0.65–0.70, different voices
    /// 0.50–0.53. 0.62 keeps every echo seen while staying above strangers.
    static let matchThreshold: Float = 0.62
    static let enrollSeconds: TimeInterval = 15
    static let classroomLabelsKey = "classroomLabels"

    private struct Stored: Codable {
        var embedding: [Float]
        var createdAt: Date
        var speechShare: Float
    }

    static var fileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Parrot", isDirectory: true)
            .appendingPathComponent("voiceprint.json")
    }

    static var embedding: [Float]? {
        guard let data = try? Data(contentsOf: fileURL),
              let stored = try? JSONDecoder().decode(Stored.self, from: data),
              !stored.embedding.isEmpty else { return nil }
        return stored.embedding
    }

    static var isEnrolled: Bool { embedding != nil }

    static func save(_ embedding: [Float], speechShare: Float) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Stored(embedding: embedding, createdAt: Date(), speechShare: speechShare))
        try data.write(to: fileURL, options: [.atomic])
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func isMe(_ embedding: [Float], mine: [Float]?, threshold: Float = matchThreshold) -> Bool {
        guard let mine, !embedding.isEmpty else { return false }
        return SpeakerProfileStore.cosine(embedding, mine) >= threshold
    }

    /// Clusters whose voice is the user's map to "Me"; the rest are unchanged.
    static func relabelMe(_ mapping: [String: String], embeddings: [String: [Float]],
                          mine: [Float]?) -> [String: String] {
        guard mine != nil else { return mapping }
        var out = mapping
        for (cluster, vector) in embeddings where isMe(vector, mine: mine) {
            out[cluster] = "Me"
        }
        return out
    }

    /// "Speaker 2" shows as "学生2" when classroom labels are on.
    static func classroomName(_ label: String, enabled: Bool) -> String {
        guard enabled, label.hasPrefix("Speaker ") else { return label }
        return "学生" + label.dropFirst("Speaker ".count)
    }

    enum EnrollError: LocalizedError {
        case tooQuiet, noMic, busy
        var errorDescription: String? {
            switch self {
            case .tooQuiet: return "没有录到足够的说话声，请靠近麦克风再试一次"
            case .noMic: return "无法打开麦克风，请在系统设置中允许 Parrot 使用麦克风"
            case .busy: return "正在录制会议，结束后再录入声纹"
            }
        }
    }

    /// Records `seconds` from the default microphone, diarizes it and keeps
    /// the main voice. Returns the share of the recording that was speech.
    @MainActor
    static func enroll(using engine: DiarizationEngine, seconds: TimeInterval = enrollSeconds,
                       progress: @escaping (Double) -> Void) async throws -> Float {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ck-voiceprint-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        try await record(to: url, seconds: seconds, progress: progress)
        let output = try await engine.diarize(audioURL: url)
        // Labels are ordered by talk time, so "Speaker 1" is the main voice.
        guard let main = output.embeddings["Speaker 1"], !main.isEmpty else { throw EnrollError.tooQuiet }
        let speech = output.segments
            .filter { $0.speakerLabel == "Speaker 1" }
            .reduce(0.0) { $0 + ($1.endTime - $1.startTime) }
        guard speech >= 6 else { throw EnrollError.tooQuiet }
        let share = Float(min(1, speech / seconds))
        try save(main, speechShare: share)
        return share
    }

    private final class Sink: @unchecked Sendable {
        var file: AVAudioFile?
        var error: Error?
    }

    @MainActor
    private static func record(to url: URL, seconds: TimeInterval,
                               progress: @escaping (Double) -> Void) async throws {
        guard await AVCaptureDevice.requestAccess(for: .audio) else { throw EnrollError.noMic }
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw EnrollError.noMic }
        let sink = Sink()
        sink.file = try AVAudioFile(forWriting: url, settings: format.settings,
                                    commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            do { try sink.file?.write(from: buffer) } catch { sink.error = error }
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw EnrollError.noMic
        }
        let steps = Int(seconds * 10)
        for step in 0..<steps {
            try? await Task.sleep(nanoseconds: 100_000_000)
            progress(Double(step + 1) / Double(steps))
        }
        input.removeTap(onBus: 0)
        engine.stop()
        sink.file = nil // closes the file
        if let error = sink.error { throw error }
    }
}
