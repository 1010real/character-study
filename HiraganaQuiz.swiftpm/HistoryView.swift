import SwiftUI

/// 保護者向けの記録画面。モード別・問題ごとの正答率と回答履歴、CSV 書き出し。
struct HistoryView: View {
    let profile: Profile

    @State private var csvURL: URL?

    private var answers: [AnswerRecord] {
        profile.answers.sorted { $0.answeredAt > $1.answeredAt }
    }

    private struct KanaStat: Identifiable {
        let question: Question
        let total: Int
        let correct: Int
        var id: String { question.id }
        var rate: Double { total == 0 ? 0 : Double(correct) / Double(total) }
    }

    /// そのモードの問題ごとの成績（にがてな順）
    private func stats(for mode: QuizMode) -> [KanaStat] {
        let grouped = Dictionary(grouping: profile.answers, by: \.questionID)
        return mode.questions.compactMap { question -> KanaStat? in
            guard let records = grouped[question.id], !records.isEmpty else { return nil }
            return KanaStat(question: question, total: records.count,
                            correct: records.filter(\.isCorrect).count)
        }
        .sorted { ($0.rate, -$0.total) < ($1.rate, -$1.total) }
    }

    var body: some View {
        List {
            if profile.answers.isEmpty {
                Text("まだ きろくが ありません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(QuizMode.allCases) { mode in
                    let modeStats = stats(for: mode)
                    if !modeStats.isEmpty {
                        Section("\(mode.title) の せいかいりつ（にがてな じゅん）") {
                            ForEach(modeStats) { stat in
                                statRow(stat)
                            }
                        }
                    }
                }

                Section("さいきんの かいとう") {
                    ForEach(answers.prefix(200)) { record in
                        HStack(alignment: .firstTextBaseline) {
                            Text(record.isCorrect ? "⭕️" : "❌")
                            Text(QuizMode.question(id: record.questionID)?.kana ?? "?")
                                .font(.title3.bold())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.answeredAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.subheadline)
                                Text("\(record.questionID)・\(record.attempt)かいめ・きこえた: \(record.heardText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(profile.name) さんの きろく")
        .toolbar {
            if let csvURL {
                ShareLink(item: csvURL) {
                    Label("CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
        .task(id: profile.answers.count) {
            csvURL = try? writeCSV()
        }
    }

    private func statRow(_ stat: KanaStat) -> some View {
        HStack {
            Text(stat.question.kana)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 88, alignment: .leading)
            ProgressView(value: stat.rate)
                .tint(stat.rate >= 0.8 ? .green : stat.rate >= 0.5 ? .orange : .red)
            Text("\(stat.correct)/\(stat.total)")
                .monospacedDigit()
                .frame(width: 64, alignment: .trailing)
        }
    }

    /// 回答記録を CSV ファイルとして一時フォルダに書き出す。
    private func writeCSV() throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current

        var lines = ["answeredAt,profile,questionID,kana,isCorrect,attempt,heardText,sessionID"]
        for record in profile.answers.sorted(by: { $0.answeredAt < $1.answeredAt }) {
            let fields = [
                formatter.string(from: record.answeredAt),
                profile.name,
                record.questionID,
                QuizMode.question(id: record.questionID)?.kana ?? "",
                record.isCorrect ? "1" : "0",
                String(record.attempt),
                record.heardText,
                record.sessionID.uuidString,
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hiragana-\(profile.name.replacingOccurrences(of: "/", with: "_")).csv")
        // Excel で文字化けしないよう BOM 付き UTF-8 にする
        let text = "\u{FEFF}" + lines.joined(separator: "\n") + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
