import Foundation

/// 出題1問ぶんの定義。`id` は記録に使うので、一度決めたら変えないこと。
struct Question: Identifiable, Hashable {
    let id: String
    let kana: String
}

enum Hiragana {
    /// 出題対象の基本ひらがな 46 文字。ID は「hira_ + ローマ字」で固定。
    private static let table: [(String, String)] = [
        ("a", "あ"), ("i", "い"), ("u", "う"), ("e", "え"), ("o", "お"),
        ("ka", "か"), ("ki", "き"), ("ku", "く"), ("ke", "け"), ("ko", "こ"),
        ("sa", "さ"), ("shi", "し"), ("su", "す"), ("se", "せ"), ("so", "そ"),
        ("ta", "た"), ("chi", "ち"), ("tsu", "つ"), ("te", "て"), ("to", "と"),
        ("na", "な"), ("ni", "に"), ("nu", "ぬ"), ("ne", "ね"), ("no", "の"),
        ("ha", "は"), ("hi", "ひ"), ("fu", "ふ"), ("he", "へ"), ("ho", "ほ"),
        ("ma", "ま"), ("mi", "み"), ("mu", "む"), ("me", "め"), ("mo", "も"),
        ("ya", "や"), ("yu", "ゆ"), ("yo", "よ"),
        ("ra", "ら"), ("ri", "り"), ("ru", "る"), ("re", "れ"), ("ro", "ろ"),
        ("wa", "わ"), ("wo", "を"), ("n", "ん"),
    ]

    static let questions: [Question] = table.map { Question(id: "hira_\($0.0)", kana: $0.1) }

    static let allKana: [String] = questions.map(\.kana)

    static func question(id: String) -> Question? {
        questions.first { $0.id == id }
    }

    /// 同じ音として扱う文字（「を」は「お」と同じ発音）
    static let sameSound: [String: Set<String>] = [
        "を": ["お"],
    ]

    /// 読み上げ用の文字。単独の「は」「へ」が助詞読み（わ・え）にならないようカタカナで読ませる。
    static func spokenForm(of kana: String) -> String {
        kana.applyingTransform(.hiraganaToKatakana, reverse: false) ?? kana
    }
}
