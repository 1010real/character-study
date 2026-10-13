import Foundation

/// 出題モード。モードを増やすときはここに追加する。
enum QuizMode: String, CaseIterable, Identifiable {
    case hiragana   // ひらがな1文字
    case word       // 2〜3文字の言葉

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hiragana: return "ひらがな 1もじ"
        case .word: return "ことば 2〜3もじ"
        }
    }

    var systemImage: String {
        switch self {
        case .hiragana: return "character"
        case .word: return "text.bubble"
        }
    }

    var questions: [Question] {
        switch self {
        case .hiragana: return Hiragana.questions
        case .word: return Words.questions
        }
    }

    /// 音声認識に「この中の言葉が言われやすい」と伝えるヒント（Apple の推奨上限 100 個まで）
    var recognitionHints: [String] {
        switch self {
        case .hiragana:
            return Hiragana.allKana
        case .word:
            return Array(questions.flatMap { [$0.kana] + $0.alternatives.prefix(1) }.prefix(100))
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
