import Foundation

/// 出題する問題を選ぶ。
/// 将来ここを差し替えて、回答履歴（正答率の低い文字など）に応じた出題にできるようにしている。
protocol QuestionPicker {
    func pick(count: Int, history: [AnswerRecord]) -> [Question]
}

/// いまの出題方法: 46文字からランダムに選ぶ（履歴は使わない）。
struct RandomQuestionPicker: QuestionPicker {
    func pick(count: Int, history: [AnswerRecord]) -> [Question] {
        Array(Hiragana.questions.shuffled().prefix(count))
    }
}
