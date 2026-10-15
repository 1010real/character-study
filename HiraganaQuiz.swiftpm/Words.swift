import Foundation

/// 「ことば」モードで出題する2〜3文字の単語。
/// 覚えたての子ども向けに、濁点・小さい文字を含まない基本のひらがなだけでできた言葉にしている。
/// ID は「word_ + ローマ字」で固定。一度決めたら変えないこと。
enum Words {
    /// (ID用ローマ字, ひらがな, 音声認識が返しそうな漢字などの書き方)
    private static let table: [(String, String, [String])] = [
        // 2もじ
        ("inu", "いぬ", ["犬"]),
        ("neko", "ねこ", ["猫"]),
        ("kuma", "くま", ["熊"]),
        ("saru", "さる", ["猿"]),
        ("ushi", "うし", ["牛"]),
        ("tori", "とり", ["鳥"]),
        ("kani", "かに", ["蟹"]),
        ("kame", "かめ", ["亀"]),
        ("ame", "あめ", ["雨", "飴"]),
        ("hana", "はな", ["花", "鼻"]),
        ("mimi", "みみ", ["耳"]),
        ("kuchi", "くち", ["口"]),
        ("ashi", "あし", ["足", "脚"]),
        ("ie", "いえ", ["家"]),
        ("umi", "うみ", ["海"]),
        ("yama", "やま", ["山"]),
        ("sora", "そら", ["空"]),
        ("hoshi", "ほし", ["星"]),
        ("tsuki", "つき", ["月"]),
        ("mori", "もり", ["森"]),
        ("kasa", "かさ", ["傘"]),
        ("kutsu", "くつ", ["靴"]),
        ("fune", "ふね", ["船", "舟"]),
        ("isu", "いす", ["椅子"]),
        ("kao", "かお", ["顔"]),
        ("yuki", "ゆき", ["雪"]),
        ("momo", "もも", ["桃"]),
        ("nashi", "なし", ["梨"]),
        // 3もじ
        ("sakura", "さくら", ["桜"]),
        ("suika", "すいか", ["西瓜"]),
        ("kitsune", "きつね", ["狐"]),
        ("tanuki", "たぬき", ["狸"]),
        ("karasu", "からす", ["烏"]),
        ("iruka", "いるか", ["海豚"]),
        ("kaeru", "かえる", ["蛙", "帰る"]),
        ("ahiru", "あひる", ["家鴨"]),
        ("tsukue", "つくえ", ["机"]),
        ("kuruma", "くるま", ["車"]),
        ("tomato", "とまと", []),
        ("meron", "めろん", []),
        ("mikan", "みかん", ["蜜柑"]),
        ("atama", "あたま", ["頭"]),
        ("onaka", "おなか", ["お腹"]),
        ("sakana", "さかな", ["魚"]),
        ("hasami", "はさみ", ["鋏"]),
        ("hotaru", "ほたる", ["蛍"]),
        ("koara", "こあら", []),
        ("futon", "ふとん", ["布団"]),
    ]

    /// 4〜5文字の言葉。こちらも基本のひらがなだけでできた言葉にしている。
    /// 絵は今は仮のもの（絵文字から作った画像）。本番の絵ができたら同じ名前の PNG に差し替える。
    private static let longTable: [(String, String, [String])] = [
        // 4もじ
        ("himawari", "ひまわり", ["向日葵"]),
        ("niwatori", "にわとり", ["鶏"]),
        ("fukurou", "ふくろう", ["梟"]),
        ("hikouki", "ひこうき", ["飛行機"]),
        ("kutsushita", "くつした", ["靴下"]),
        ("takenoko", "たけのこ", ["筍"]),
        ("kamakiri", "かまきり", ["蟷螂"]),
        ("aomushi", "あおむし", ["青虫"]),
        ("taiyaki", "たいやき", ["鯛焼き", "鯛焼"]),
        ("omatsuri", "おまつり", ["お祭り"]),
        ("fuusen", "ふうせん", ["風船"]),
        ("sankaku", "さんかく", ["三角"]),
        ("suitou", "すいとう", ["水筒"]),
        ("rousoku", "ろうそく", ["蝋燭"]),
        ("keisatsu", "けいさつ", ["警察"]),
        ("kaminari", "かみなり", ["雷"]),
        ("shimauma", "しまうま", ["縞馬"]),
        ("shirokuma", "しろくま", ["白熊"]),
        ("tsunahiki", "つなひき", ["綱引き"]),
        ("ayatori", "あやとり", ["綾取り"]),
        // 5もじ
        ("katatsumuri", "かたつむり", ["蝸牛"]),
        ("satsumaimo", "さつまいも", ["薩摩芋"]),
        ("namakemono", "なまけもの", ["怠け者"]),
        ("sentakuki", "せんたくき", ["洗濯機"]),
        ("yuuenchi", "ゆうえんち", ["遊園地"]),
        ("sakuramochi", "さくらもち", ["桜餅"]),
        ("hinamatsuri", "ひなまつり", ["雛祭り"]),
        ("okaasan", "おかあさん", ["お母さん"]),
        ("otousan", "おとうさん", ["お父さん"]),
        ("oniisan", "おにいさん", ["お兄さん"]),
        ("oneesan", "おねえさん", ["お姉さん"]),
    ]

    /// 「ことば 2〜3もじ」モード（声に出して読む）の問題
    static let questions: [Question] = table.map {
        Question(id: "word_\($0.0)", kana: $0.1, alternatives: $0.2, imageName: imageName($0.0))
    }

    /// 「ことば 4〜5もじ」モード（声に出して読む）の問題。ID は 2〜3もじ と同じく「word_ + ローマ字」。
    static let longQuestions: [Question] = longTable.map {
        Question(id: "word_\($0.0)", kana: $0.1, alternatives: $0.2, imageName: imageName($0.0))
    }

    /// 「えを えらぶ」モードの問題。読む問題と記録を分けるため ID は「pict_ + ローマ字」。
    static let pictureQuestions: [Question] = table.map {
        Question(id: "pict_\($0.0)", kana: $0.1, imageName: imageName($0.0))
    }

    /// 「えを えらぶ 4〜5もじ」モードの問題。ID は「pict_ + ローマ字」。
    static let longPictureQuestions: [Question] = longTable.map {
        Question(id: "pict_\($0.0)", kana: $0.1, imageName: imageName($0.0))
    }

    /// 絵は Assets.xcassets/Words/word_<ローマ字>.imageset に入っている
    private static func imageName(_ romaji: String) -> String {
        "word_\(romaji)"
    }
}
