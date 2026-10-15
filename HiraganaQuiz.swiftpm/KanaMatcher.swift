import Foundation

/// 音声認識の結果が、出題したひらがなの発音と合っているかを判定する。
enum KanaMatcher {
    /// 候補のどれか1つでも合っていれば正解。
    static func matches(_ question: Question, candidates: [String]) -> Bool {
        candidates.contains { matches(question, heard: $0) }
    }

    static func matches(_ question: Question, heard: String) -> Bool {
        let target = question.kana
        let accepted = [target] + (Hiragana.sameSound[target].map(Array.init) ?? [])
        let core = String(heard.filter { !$0.isWhitespace && !$0.isPunctuation && $0 != "ー" })

        // 「いぬ」→「犬」のように、問題ごとに登録した書き方と同じなら正解
        if question.alternatives.contains(core) {
            return true
        }

        // 1音だけの発話は「歩」「木」のような同じ音の漢字1文字で返ってくることが多い。
        // 漢字1文字の読みは1つに決まらない（「歩」は ほ・ふ・ある…）ので、表で判定する。
        if let kanji = core.first, core.allSatisfy({ $0 == kanji }),
           accepted.contains(where: { Hiragana.kanjiHomophones[$0]?.contains(kanji) == true }) {
            return true
        }

        let reading = hiraganaReading(of: heard)
        guard !reading.isEmpty else { return false }
        if accepted.contains(where: { isSameSound(kana: $0, reading: reading) }) {
            return true
        }

        // 「ひこうき」が「ヒコーキ」、「ふうせん」が「フーセン」のように、のばす音を「ー」で返されることがある
        let heardKey = longVowelInsensitiveKey(hiraganaKeepingLongMark(heard))
        return accepted.contains { longVowelInsensitiveKey($0) == heardKey }
    }

    /// のばす音を取りのぞいて比べるためのキー。
    /// 「ー」と、前の文字と同じ母音をのばしている「あいうえお」（こう・こお・けい・さあ…）を消す。
    /// 例: 「ひこうき」「ひこーき」→「ひこき」、「おねえさん」→「おねさん」
    static func longVowelInsensitiveKey(_ text: String) -> String {
        var result = ""
        var previousVowel: Character?
        for c in text {
            if c == "ー" { continue }
            if let previousVowel, lengthens(c, after: previousVowel) { continue }
            result.append(c)
            // 「きょ」の「ょ」のような小さい文字は、その母音で前の音を置きかえる
            previousVowel = smallKanaVowels[c] ?? vowel(of: String(c))
        }
        return result
    }

    /// 母音 `vowel` の音のあとで、`c` がその音をのばしているだけか
    private static func lengthens(_ c: Character, after vowel: Character) -> Bool {
        switch (vowel, c) {
        case ("あ", "あ"), ("い", "い"), ("う", "う"), ("え", "え"), ("え", "い"), ("お", "お"), ("お", "う"):
            return true
        default:
            return false
        }
    }

    /// 「ー」を残したまま、ひらがなにする（カタカナ→ひらがな、漢字は読みに変換）
    private static func hiraganaKeepingLongMark(_ text: String) -> String {
        let hiragana = text.applyingTransform(.hiraganaToKatakana, reverse: true) ?? text
        let converted = containsKanji(hiragana) ? readingOfKanji(hiragana) : hiragana
        return String(converted.filter { isHiragana($0) || $0 == "ー" })
    }

    /// 「か」「かあ」「かっ」「かか」「いぬー」のように、目標＋（最後の文字・その母音・小さい母音・っ）だけなら同じ音とみなす。
    private static func isSameSound(kana: String, reading: String) -> Bool {
        guard reading.hasPrefix(kana) else { return false }
        let rest = reading.dropFirst(kana.count)
        if rest.isEmpty { return true }

        var allowed: Set<Character> = ["っ"]
        if let last = kana.last { allowed.insert(last) }
        if let vowel = vowel(of: kana) {
            allowed.insert(vowel)
            if let small = smallVowels[vowel] { allowed.insert(small) }
        }
        return rest.allSatisfy { allowed.contains($0) }
    }

    /// 小さい文字が表す母音（「きゃ」→「あ」、「しゅ」→「う」、「ちょ」→「お」）
    private static let smallKanaVowels: [Character: Character] = [
        "ゃ": "あ", "ゅ": "う", "ょ": "お",
        "ぁ": "あ", "ぃ": "い", "ぅ": "う", "ぇ": "え", "ぉ": "お",
    ]

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
        // 「じ」「び」「ぴ」が、アルファベットの「G」「B」「P」で返ってくることがある
        if let letterReading = letterReadings[halfWidth.uppercased()] {
            return letterReading
        }

        let hiragana = text.applyingTransform(.hiraganaToKatakana, reverse: true) ?? text
        var converted = containsKanji(hiragana) ? readingOfKanji(hiragana) : hiragana
        // 「A」「Ka」のようにローマ字で返ってきた場合もひらがなにする
        if converted.contains(where: { $0.isASCII && $0.isLetter }) {
            converted = converted.lowercased().applyingTransform(.latinToHiragana, reverse: false) ?? converted
        }
        return String(converted.filter(isHiragana))
    }

    private static let letterReadings: [String: String] = [
        "B": "び", "C": "し", "G": "じ", "P": "ぴ",
    ]

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
