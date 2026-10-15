import Foundation

/// 出題モード。モードを増やすときはここに追加する。
enum QuizMode: String, CaseIterable, Identifiable {
    case hiragana   // ひらがな1文字
    case word       // 2〜3文字の言葉
    case longWord   // 4〜5文字の言葉
    case picture    // 言葉を読んで、あう絵を4つから選ぶ

    var id: String { rawValue }

    /// 「はつおん」メニューの中にあるモード（文字数を選ぶ）
    static let pronunciationModes: [QuizMode] = [.hiragana, .word, .longWord]

    /// 画面上部やきろく画面に出す名前
    var title: String {
        switch self {
        case .hiragana: return "はつおん 1もじ"
        case .word: return "はつおん 2〜3もじ"
        case .longWord: return "はつおん 4〜5もじ"
        case .picture: return "えを えらぶ"
        }
    }

    /// 「はつおん」メニューのボタンに出す名前
    var shortTitle: String {
        switch self {
        case .hiragana: return "1もじ"
        case .word: return "2〜3もじ"
        case .longWord: return "4〜5もじ"
        case .picture: return "えを えらぶ"
        }
    }

    var systemImage: String {
        switch self {
        case .hiragana: return "character"
        case .word: return "text.bubble"
        case .longWord: return "text.bubble.fill"
        case .picture: return "photo.on.rectangle"
        }
    }

    var questions: [Question] {
        switch self {
        case .hiragana: return Hiragana.questions
        case .word: return Words.questions
        case .longWord: return Words.longQuestions
        case .picture: return Words.pictureQuestions
        }
    }

    /// 声で答えるモードか（マイクと音声認識を使うか）
    var usesVoice: Bool {
        self != .picture
    }

    /// 録音の長さ（秒）。長い言葉は1文字ずつゆっくり読むことが多いので、長めに待つ。
    /// - max: 最大の録音時間
    /// - silence: 声が聞こえたあと、この時間しゃべらなければ終わる
    var listenTiming: (max: TimeInterval, silence: TimeInterval) {
        switch self {
        case .hiragana: return (4, 1.0)
        case .word: return (5, 1.2)
        case .longWord: return (8, 1.8)
        case .picture: return (0, 0)
        }
    }

    /// 絵を選ぶときの選択肢の数
    static let pictureChoiceCount = 4

    /// 音声認識に「この中の言葉が言われやすい」と伝えるヒント（Apple の推奨上限 100 個まで）
    var recognitionHints: [String] {
        switch self {
        case .hiragana:
            return Hiragana.allKana
        case .word, .longWord:
            return Array(questions.flatMap { [$0.kana] + $0.alternatives.prefix(1) }.prefix(100))
        case .picture:
            return []
        }
    }

    /// すべてのモードから設問 ID で問題を探す（記録の表示用）
    static func question(id: String) -> Question? {
        for mode in allCases {
            if let question = mode.questions.first(where: { $0.id == id }) {
                return question
            }
        }
        return nil
    }
}
