# character-study

子ども向けの文字学習アプリです。

## ひらがなクイズ（`HiraganaQuiz.swiftpm`）

1. ひらがなを1文字表示する
2. 子どもが声に出して読む（マイクで聞き取る）
3. 合っていれば「せいかい！」、違えば「ちがうよ？ ただしくは〇〇だよ」と読み上げる
4. これを10問くり返す

- 起動時に子どもの名前を選ぶとその子として遊べます（パスワードなし）。アカウントは「＋ ふやす」で追加し、長押しで削除します。
- 回答するたびに **日時・設問ID・正解/不正解** などを端末内に記録します。名前を選んだあとの「きろく」画面で、文字ごとの正答率と履歴を確認したり、CSV で書き出したりできます。
- 音声認識と読み上げには iPhone / Mac に標準で入っている機能（Speech / AVSpeechSynthesizer）を使います。

### 必要なもの

- Mac と Xcode 15 以降（App Store から無料でインストールできます）
- iPhone で動かす場合: iOS 17 以降の iPhone と USB ケーブル、Apple ID（無料で可）

### 最初に1回だけ：署名の設定（Mac・iPhone 共通）

アプリを動かすには「誰が作ったか」の署名が必要です。設定しないと
`Signing for "HiraganaQuiz" requires a development team` というエラーでビルドが止まります。

1. Xcode > Settings… > **Accounts** で、左下の「＋」→「Apple ID」から自分の Apple ID を追加する（無料の Apple ID で可）
2. Finder で `HiraganaQuiz.swiftpm` をダブルクリックして Xcode で開く
3. 左のファイル一覧の一番上（HiraganaQuiz）を選ぶ → **Signing & Capabilities** タブ → **Team** で
   「（自分の名前）(Personal Team)」を選ぶ
4. Xcode が `Package.swift` の `teamIdentifier` に Team ID（英数字10桁）を書き込むので、この変更はコミットしておく

### Mac で動かす（Apple Silicon の Mac）

1. 上の「署名の設定」を済ませる
2. 画面上部の実行先から **My Mac (Designed for iPad)** を選ぶ
3. ▶︎（Run）を押す。初回はマイクと音声認識の許可を求められるので「許可」を選ぶ

### iPhone で動かす

1. iPhone を Mac にケーブルでつなぐ
2. 上の「署名の設定」を済ませる
3. 実行先に自分の iPhone を選んで ▶︎ を押す
4. 初回は iPhone 側で次の設定が必要です
   - 設定 > プライバシーとセキュリティ > **デベロッパモード** をオンにする（iPhone が再起動します）
   - 設定 > 一般 > VPN とデバイス管理 で、自分の Apple ID の開発元を「信頼」する
5. 無料の Apple ID で入れたアプリは **7日で起動できなくなります**。そうなったら、もう一度 Xcode から ▶︎ で入れ直してください。
   **アプリは削除せずに上書きで入れ直してください**（記録が残ります）

### 記録（データ）について

- 記録は端末の中（このアプリ専用の保存領域）に保存されます。アプリの再起動や、Xcode での再ビルド・上書きインストールでは消えません。
- **アプリを削除すると記録も消えます。** 心配なときは「きろく」画面の CSV 書き出しで控えを取っておいてください。
- iPhone と Mac の記録は別々です（同期はしません）。
- バンドルID（`local.characterstudy.HiraganaQuiz`）を変えると別のアプリ扱いになり、記録を引き継げません。

### 設問ID

設問IDは `hira_` + ローマ字で固定しています（例: `hira_a`、`hira_ka`、`hira_shi`、`hira_wo`、`hira_n`）。
一覧は `HiraganaQuiz.swiftpm/Hiragana.swift` にあります。

CSV の列: `answeredAt, profile, questionID, kana, isCorrect(1/0), attempt(同じ問題の何回目か), heardText(聞き取った言葉), sessionID(10問セットごとのID)`

### うまく聞き取れないとき

- 静かな場所で、マイクに近づいて、1文字だけはっきり言ってもらってください
- 1文字だけの発話は音声認識が苦手なので、聞き間違えることがあります。
  間違ったときの画面に小さく表示される「きこえたことば」を見ると、何と認識されたかがわかります
- 何も聞き取れなかったときは記録せず、もう一度言ってもらいます

### ファイル構成

| ファイル | 内容 |
| --- | --- |
| `Package.swift` | アプリの設定（名前、バンドルID、マイク・音声認識の許可文） |
| `Hiragana.swift` | 出題するひらがなと設問ID |
| `QuestionPicker.swift` | 出題の選び方（今はランダム。将来、苦手な文字を多く出すように変更する場所） |
| `QuizModel.swift` | クイズの進行と回答の記録 |
| `SpeechListener.swift` | 録音と音声認識 |
| `KanaMatcher.swift` | 聞き取った言葉が正しい発音かの判定 |
| `Speaker.swift` | 読み上げ |
| `Models.swift` | 保存するデータ（アカウント、回答記録） |
| `ProfileSelectView.swift` / `QuizView.swift` / `HistoryView.swift` | 画面 |
