import Foundation

/// 音声認識の結果が、出題したひらがなの発音と合っているかを判定する。
enum KanaMatcher {
    /// 候補のどれか1つでも合っていれば正解。
    static func matches(target: String, candidates: [String]) -> Bool {
        candidates.contains { matches(target: target, heard: $0) }
    }

    static func matches(target: String, heard: String) -> Bool {
        let reading = hiraganaReading(of: heard)
        guard !reading.isEmpty else { return false }

        let accepted = [target] + (Hiragana.sameSound[target].map(Array.init) ?? [])
        return accepted.contains { isSameSound(kana: $0, reading: reading) }
    }

    /// 「か」「かあ」「かっ」「かか」のように、目標の文字＋（同じ文字・母音・小さい母音・っ）だけなら同じ音とみなす。
    private static func isSameSound(kana: String, reading: String) -> Bool {
        guard reading.hasPrefix(kana) else { return false }
        let rest = reading.dropFirst(kana.count)
        if rest.isEmpty { return true }

        var allowed: Set<Character> = ["っ"]
        allowed.formUnion(kana)
        if let vowel = vowel(of: kana) {
            allowed.insert(vowel)
            if let small = smallVowels[vowel] { allowed.insert(small) }
        }
        return rest.allSatisfy { allowed.contains($0) }
    }

    private static let smallVowels: [Character: Character] = [
        "あ": "ぁ", "い": "ぃ", "う": "ぅ", "え": "ぇ", "お": "ぉ",
    ]

    /// 「か」→「あ」のように、その文字の母音のひらがなを返す（「ん」は nil）。
    private static func vowel(of kana: String) -> Character? {
        guard let romaji = kana.applyingTransform(.latinToHiragana, reverse: true),
              let last = romaji.last else { return nil }
        switch last {
        case "a": return "あ"
        case "i": return "い"
        case "u": return "う"
        case "e": return "え"
        case "o": return "お"
        default: return nil
        }
    }

    /// 認識結果の文字列を、ひらがなの読みだけにする。
    /// 例: 「カ」→「か」、「木」→「き」、「あー。」→「あ」
    static func hiraganaReading(of text: String) -> String {
        // 「に」が「2」のように数字で返ってくることがある
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let halfWidth = trimmed.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? trimmed
        if let digitReading = digitReadings[halfWidth] {
            return digitReading
        }

        let hiragana = text.applyingTransform(.hiraganaToKatakana, reverse: true) ?? text
        var converted = containsKanji(hiragana) ? readingOfKanji(hiragana) : hiragana
        // 「A」「Ka」のようにローマ字で返ってきた場合もひらがなにする
        if converted.contains(where: { $0.isASCII && $0.isLetter }) {
            converted = converted.lowercased().applyingTransform(.latinToHiragana, reverse: false) ?? converted
        }
        return String(converted.filter(isHiragana))
    }

    private static let digitReadings: [String: String] = [
        "1": "いち", "2": "に", "3": "さん", "4": "し", "5": "ご",
        "6": "ろく", "7": "なな", "8": "はち", "9": "く", "0": "れい",
    ]

    private static func isHiragana(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy { (0x3041...0x3096).contains($0.value) }
    }

    private static func containsKanji(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value) }
    }

    /// 漢字まじりの文字列を、日本語のトークナイザでローマ字読みにしてから、ひらがなに戻す。
    private static func readingOfKanji(_ text: String) -> String {
        let cfText = text as CFString
        let range = CFRange(location: 0, length: CFStringGetLength(cfText))
        let locale = Locale(identifier: "ja") as CFLocale
        let tokenizer = CFStringTokenizerCreate(nil, cfText, range, kCFStringTokenizerUnitWordBoundary, locale)

        var latin = ""
        var tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0)
        while tokenType.rawValue != 0 {
            if let transcription = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                latin += transcription
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        return latin.applyingTransform(.latinToHiragana, reverse: false) ?? latin
    }
}
