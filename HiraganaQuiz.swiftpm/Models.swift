import Foundation
import SwiftData

// 注意: 既存の記録を引き継ぐため、今後プロパティを追加するときは必ず初期値を付けること。

@Model
final class Profile {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🙂"
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \AnswerRecord.profile)
    var answers: [AnswerRecord] = []

    init(name: String, emoji: String) {
        self.name = name
        self.emoji = emoji
    }
}

@Model
final class AnswerRecord {
    var id: UUID = UUID()
    /// 回答した日時
    var answeredAt: Date = Date()
    /// 設問 ID（例: "hira_ka"）
    var questionID: String = ""
    var isCorrect: Bool = false
    /// 音声認識で聞き取った文字列（判定の確認用）
    var heardText: String = ""
    /// 1回の10問セットを表す ID
    var sessionID: UUID = UUID()
    /// 同じ問題の何回目の回答か（1始まり）
    var attempt: Int = 1
    var profile: Profile?

    init(questionID: String, isCorrect: Bool, heardText: String, sessionID: UUID, attempt: Int) {
        self.questionID = questionID
        self.isCorrect = isCorrect
        self.heardText = heardText
        self.sessionID = sessionID
        self.attempt = attempt
    }
}
