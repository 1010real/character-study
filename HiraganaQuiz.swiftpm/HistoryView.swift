import SwiftUI

/// 保護者向けの記録画面。文字ごとの正答率と回答履歴、CSV 書き出し。
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

    private var stats: [KanaStat] {
        let grouped = Dictionary(grouping: profile.answers, by: \.questionID)
        return Hiragana.questions.compactMap { question in
            guard let records = grouped[question.id], !records.isEmpty else { return nil }
            return KanaStat(question: question, total: records.count,
                            correct: records.filter(\.isCorrect).count)
        }
    }

    var body: some View {
        List {
            if profile.answers.isEmpty {
                Text("まだ きろくが ありません")
                    .foregroundStyle(.secondary)
            } else {
                Section("もじごとの せいかいりつ（にがてな じゅん）") {
                    ForEach(stats.sorted { ($0.rate, -$0.total) < ($1.rate, -$1.total) }) { stat in
                        HStack {
                            Text(stat.question.kana)
                                .font(.title2.bold())
                                .frame(width: 44)
                            ProgressView(value: stat.rate)
                                .tint(stat.rate >= 0.8 ? .green : stat.rate >= 0.5 ? .orange : .red)
                            Text("\(stat.correct)/\(stat.total)")
                                .monospacedDigit()
                                .frame(width: 64, alignment: .trailing)
                        }
                    }
                }

                Section("さいきんの かいとう") {
                    ForEach(answers.prefix(200)) { record in
                        HStack(alignment: .firstTextBaseline) {
                            Text(record.isCorrect ? "⭕️" : "❌")
                            Text(Hiragana.question(id: record.questionID)?.kana ?? "?")
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
                Hiragana.question(id: record.questionID)?.kana ?? "",
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
