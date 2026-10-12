import Foundation
import AVFoundation

/// 日本語の読み上げ。`speak` は読み上げが終わるまで待つ。
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var pending: (utterance: ObjectIdentifier, continuation: CheckedContinuation<Void, Never>)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) async {
        // 読み上げ中のものがあれば打ち切る
        finishPending()
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.15

        await withCheckedContinuation { continuation in
            pending = (ObjectIdentifier(utterance), continuation)
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        finishPending()
    }

    private func finishPending() {
        pending?.continuation.resume()
        pending = nil
    }

    private func finished(_ id: ObjectIdentifier) {
        guard pending?.utterance == id else { return }
        finishPending()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }
}
