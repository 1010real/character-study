import Foundation
import SwiftData

@MainActor
final class QuizModel: ObservableObject {
    enum Phase: Equatable {
        case ready      // 発音を待っている
        case listening  // 録音中
        case judging    // 判定中
        case correct
        case wrong
        case finished   // 全問おわり
    }

    let questionCount = 10

    @Published private(set) var questions: [Question] = []
    @Published private(set) var index = 0
    @Published private(set) var score = 0
    @Published private(set) var phase: Phase = .ready
    /// 直近に聞き取った言葉（保護者向けの確認用）
    @Published private(set) var heardText = ""
    @Published private(set) var message = ""
    @Published var errorMessage: String?

    private let profile: Profile
    private let context: ModelContext
    private let picker: any QuestionPicker
    private let listener = SpeechListener()
    private let speaker = Speaker()

    private var sessionID = UUID()
    /// いまの問題で何回目の回答か
    private var attempt = 1

    init(profile: Profile, context: ModelContext, picker: any QuestionPicker = RandomQuestionPicker()) {
        self.profile = profile
        self.context = context
        self.picker = picker
    }

    var current: Question? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    func start() {
        sessionID = UUID()
        questions = picker.pick(count: questionCount, history: profile.answers)
        index = 0
        score = 0
        attempt = 1
        heardText = ""
        message = "こえに だして よんでね"
        phase = .ready
    }

    func listen() async {
        guard let question = current, phase == .ready || phase == .wrong else { return }
        speaker.stop()
        phase = .listening
        heardText = ""
        message = "きいてるよ…"

        let candidates: [String]
        do {
            candidates = try await listener.listen(hints: Hiragana.allKana)
        } catch {
            errorMessage = error.localizedDescription
            message = "こえに だして よんでね"
            phase = .ready
            return
        }
        // 途中で画面を閉じた・別の問題に進んだ場合は何もしない
        guard phase == .listening, current == question else { return }

        if candidates.isEmpty {
            // 何も聞き取れなかったときは回答として記録せず、もう一度言ってもらう
            phase = .ready
            message = "きこえなかったよ。もういちど いってね"
            await speaker.speak("きこえなかったよ。もういちど いってね")
            return
        }

        phase = .judging
        heardText = candidates.first ?? ""
        let isCorrect = KanaMatcher.matches(target: question.kana, candidates: candidates)
        record(question: question, isCorrect: isCorrect, heard: candidates.joined(separator: " / "))

        if isCorrect {
            score += 1
            phase = .correct
            message = "せいかい！"
            await speaker.speak("せいかい！")
            try? await Task.sleep(for: .seconds(0.5))
            guard phase == .correct, current == question else { return }
            next()
        } else {
            phase = .wrong
            message = "ちがうよ？ ただしくは「\(question.kana)」だよ"
            await speakCorrectAnswer(prefix: "ちがうよ？")
        }
    }

    /// 録音を途中で止めて判定する
    func stopListening() {
        guard phase == .listening else { return }
        listener.stop()
    }

    /// 正しい読み方をもう一度聞かせる
    func speakCorrectAnswer(prefix: String = "") async {
        guard let question = current else { return }
        let spoken = Hiragana.spokenForm(of: question.kana)
        await speaker.speak("\(prefix) ただしくは、「\(spoken)」、だよ")
    }

    func next() {
        speaker.stop()
        if index + 1 < questions.count {
            index += 1
            attempt = 1
            heardText = ""
            message = "こえに だして よんでね"
            phase = .ready
        } else {
            phase = .finished
            let text = "おしまい！ \(questions.count)もん ちゅう、\(score)もん せいかい！"
            Task { await speaker.speak(text) }
        }
    }

    /// 画面を閉じるときに録音・読み上げを止める
    func cancel() {
        listener.stop()
        speaker.stop()
        phase = .ready
    }

    private func record(question: Question, isCorrect: Bool, heard: String) {
        let answer = AnswerRecord(
            questionID: question.id,
            isCorrect: isCorrect,
            heardText: heard,
            sessionID: sessionID,
            attempt: attempt
        )
        // SwiftData では、挿入してからリレーションを設定する
        context.insert(answer)
        answer.profile = profile
        do {
            try context.save()
        } catch {
            errorMessage = "きろくの ほぞんに しっぱいしました: \(error.localizedDescription)"
        }
        attempt += 1
    }
}
