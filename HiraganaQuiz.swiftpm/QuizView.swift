import SwiftUI
import SwiftData

struct QuizView: View {
    @StateObject private var model: QuizModel
    @Environment(\.dismiss) private var dismiss
    @State private var authorized: Bool?

    init(profile: Profile, mode: QuizMode, context: ModelContext) {
        _model = StateObject(wrappedValue: QuizModel(profile: profile, mode: mode, context: context))
    }

    var body: some View {
        Group {
            if let authorized {
                if !authorized {
                    permissionMessage
                } else if model.phase == .finished {
                    resultView
                } else {
                    questionView
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .navigationTitle(model.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard authorized == nil else { return }
            authorized = await SpeechListener.requestAuthorization()
            model.start()
        }
        .onDisappear { model.cancel() }
        .alert("エラー", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    // MARK: - 問題

    private var questionView: some View {
        VStack(spacing: 24) {
            Text("\(model.index + 1) / \(model.questions.count)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(model.current?.kana ?? "")
                .font(.system(size: kanaFontSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .padding(.horizontal, 24)
                .frame(minWidth: 260, maxWidth: 360, minHeight: 260, maxHeight: 260)
                .background(cardColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 40))
                .overlay(alignment: .topTrailing) {
                    if model.phase == .correct {
                        Text("⭕️").font(.system(size: 72)).offset(x: 20, y: -20)
                    }
                }
                .animation(.spring, value: model.phase)

            Text(model.message)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(minHeight: 70)

            if model.phase == .wrong, !model.heardText.isEmpty {
                Text("きこえたことば: \(model.heardText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            controls
                .frame(minHeight: 140)
        }
    }

    /// 文字数が多いほど小さくして、カードに収める
    private var kanaFontSize: CGFloat {
        switch model.current?.kana.count ?? 1 {
        case 1: return 180
        case 2: return 130
        default: return 96
        }
    }

    private var cardColor: Color {
        switch model.phase {
        case .correct: return .green
        case .wrong: return .red
        default: return .orange
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch model.phase {
        case .ready:
            Button {
                Task { await model.listen() }
            } label: {
                micCircle(systemImage: "mic.fill", color: .orange)
            }
            .buttonStyle(.plain)
        case .listening:
            Button {
                model.stopListening()
            } label: {
                micCircle(systemImage: "waveform", color: .red)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            .buttonStyle(.plain)
        case .judging, .correct, .finished:
            EmptyView()
        case .wrong:
            HStack(spacing: 16) {
                Button {
                    Task { await model.speakCorrectAnswer() }
                } label: {
                    Label("きく", systemImage: "speaker.wave.2.fill")
                }
                Button {
                    Task { await model.listen() }
                } label: {
                    Label("もういちど", systemImage: "mic.fill")
                }
                Button {
                    model.next()
                } label: {
                    Label("つぎへ", systemImage: "arrow.right")
                }
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    private func micCircle(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 52, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 120, height: 120)
            .background(color, in: Circle())
            .shadow(radius: 6)
    }

    // MARK: - 結果

    private var resultView: some View {
        VStack(spacing: 28) {
            Text("おしまい！")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("\(model.questions.count)もん ちゅう \(model.score)もん せいかい")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(String(repeating: "⭐️", count: model.score))
                .font(.system(size: 36))
                .multilineTextAlignment(.center)

            Button("もういちど あそぶ") { model.start() }
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            Button("おわる") { dismiss() }
                .font(.system(size: 20, design: .rounded))
        }
    }

    private var permissionMessage: some View {
        VStack(spacing: 16) {
            Text("マイクと おんせいにんしきの きょかが ひつようです")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("「せってい」アプリで、このアプリの マイクと おんせいにんしきを オンにしてください。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}
