import Foundation

/// 出題する問題を選ぶ。
/// 将来ここを差し替えて、回答履歴（正答率の低い文字など）に応じた出題にできるようにしている。
protocol QuestionPicker {
    func pick(from questions: [Question], count: Int, history: [AnswerRecord]) -> [Question]
}

/// いまの出題方法: そのモードの問題からランダムに選ぶ（履歴は使わない）。
struct RandomQuestionPicker: QuestionPicker {
    func pick(from questions: [Question], count: Int, history: [AnswerRecord]) -> [Question] {
        Array(questions.shuffled().prefix(count))
    }
}
