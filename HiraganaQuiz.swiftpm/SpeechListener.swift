import Foundation
import Speech
import AVFoundation

enum ListenError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "おんせいにんしきが つかえません。ネットワークや せっていを かくにんしてください。"
        }
    }
}

/// マイクで録音しながら日本語の音声認識を行い、認識候補の文字列を返す。
///
/// 音声タップや認識コールバックはバックグラウンドスレッドから呼ばれるため、
/// 状態はすべて専用のシリアルキュー `queue` 上でだけ触る。
final class SpeechListener: @unchecked Sendable {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let queue = DispatchQueue(label: "SpeechListener")

    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: CheckedContinuation<[String], Error>?
    private var candidates: [String] = []
    /// 古いタイマーが新しい録音を止めないよう、録音ごとに番号を振る
    private var generation = 0
    private var silenceWorkItem: DispatchWorkItem?

    /// マイクと音声認識の利用許可を求める。両方許可されたら true。
    static func requestAuthorization() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    /// 録音して認識候補を返す。何も聞き取れなければ空配列。
    /// - Parameters:
    ///   - hints: 認識されやすくしたい語（ひらがな一覧など）
    ///   - maxDuration: 最大録音秒数
    ///   - silenceAfterSpeech: 声を検出したあと、この秒数だけ新しい認識がなければ終了
    func listen(hints: [String], maxDuration: TimeInterval = 4, silenceAfterSpeech: TimeInterval = 1.0) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.start(hints: hints, maxDuration: maxDuration,
                                   silenceAfterSpeech: silenceAfterSpeech, continuation: continuation)
                } catch {
                    self.cleanUp()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 録音を途中で止めて、ここまでの結果で判定させる。
    func stop() {
        queue.async {
            self.endAudio(generation: self.generation)
        }
    }

    // MARK: - 以下は queue 上でのみ呼ぶ

    private func start(hints: [String], maxDuration: TimeInterval, silenceAfterSpeech: TimeInterval,
                       continuation: CheckedContinuation<[String], Error>) throws {
        // 前回の録音が残っていれば終わらせる
        complete()

        guard let recognizer, recognizer.isAvailable else {
            throw ListenError.recognizerUnavailable
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = hints

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        try engine.start()

        generation += 1
        let current = generation
        self.engine = engine
        self.request = request
        self.continuation = continuation
        self.candidates = []

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            // SFSpeechRecognitionResult は Sendable ではないので、文字列にしてからキューに渡す
            let texts = result?.transcriptions.map(\.formattedString) ?? []
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            self.queue.async {
                self.handle(texts: texts, isFinal: isFinal, failed: failed, generation: current,
                            silenceAfterSpeech: silenceAfterSpeech)
            }
        }

        queue.asyncAfter(deadline: .now() + maxDuration) { [weak self] in
            self?.endAudio(generation: current)
        }
    }

    private func handle(texts: [String], isFinal: Bool, failed: Bool, generation current: Int,
                        silenceAfterSpeech: TimeInterval) {
        guard current == generation, continuation != nil else { return }

        for text in texts where !text.isEmpty && !candidates.contains(text) {
            candidates.append(text)
        }

        if isFinal || failed {
            complete()
            return
        }

        if !texts.isEmpty {
            silenceWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.endAudio(generation: current)
            }
            silenceWorkItem = item
            queue.asyncAfter(deadline: .now() + silenceAfterSpeech, execute: item)
        }
    }

    /// 録音を止める。認識の最終結果を少し待ってから完了させる。
    private func endAudio(generation current: Int) {
        guard current == generation, continuation != nil, engine != nil else { return }
        stopEngine()
        request?.endAudio()
        queue.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, current == self.generation else { return }
            self.complete()
        }
    }

    private func complete() {
        let continuation = self.continuation
        let result = candidates
        cleanUp()
        continuation?.resume(returning: result)
    }

    private func stopEngine() {
        guard let engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
    }

    private func cleanUp() {
        silenceWorkItem?.cancel()
        silenceWorkItem = nil
        stopEngine()
        task?.cancel()
        task = nil
        request = nil
        continuation = nil
        candidates = []
    }
}
