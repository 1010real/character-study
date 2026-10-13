import SwiftUI
import SwiftData

/// 起動時の画面。名前を選ぶとその子のアカウントで遊べる。
struct ProfileSelectView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var showingAdd = false
    @State private var profileToDelete: Profile?

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("だれが あそぶ？")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .padding(.top, 24)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(profiles) { profile in
                            NavigationLink(value: profile) {
                                ProfileCard(emoji: profile.emoji, name: profile.name)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("けす", systemImage: "trash", role: .destructive) {
                                    profileToDelete = profile
                                }
                            }
                        }

                        Button {
                            showingAdd = true
                        } label: {
                            ProfileCard(emoji: "➕", name: "ふやす")
                                .opacity(0.6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    if !profiles.isEmpty {
                        Text("ながおしで けせます")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationDestination(for: Profile.self) { profile in
                ProfileHomeView(profile: profile)
            }
            .sheet(isPresented: $showingAdd) {
                AddProfileView { name, emoji in
                    context.insert(Profile(name: name, emoji: emoji))
                    try? context.save()
                }
            }
            .confirmationDialog(
                "「\(profileToDelete?.name ?? "")」と きろくを ぜんぶ けしますか？",
                isPresented: Binding(
                    get: { profileToDelete != nil },
                    set: { if !$0 { profileToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("けす", role: .destructive) {
                    if let profile = profileToDelete {
                        context.delete(profile)
                        try? context.save()
                    }
                    profileToDelete = nil
                }
                Button("やめる", role: .cancel) { profileToDelete = nil }
            }
        }
    }
}

private struct ProfileCard: View {
    let emoji: String
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 64))
            Text(name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 24))
    }
}

/// アカウント追加（保護者が操作する想定）
private struct AddProfileView: View {
    let onAdd: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "🐶"

    private let emojis = ["🐶", "🐱", "🐰", "🐻", "🐼", "🐸", "🐧", "🦁", "🐯", "🐨", "🐵", "🦊"]

    var body: some View {
        NavigationStack {
            Form {
                Section("なまえ") {
                    TextField("なまえ", text: $name)
                }
                Section("アイコン") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))]) {
                        ForEach(emojis, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 36))
                                .padding(6)
                                .background(item == emoji ? Color.orange.opacity(0.3) : .clear,
                                            in: RoundedRectangle(cornerRadius: 12))
                                .onTapGesture { emoji = item }
                        }
                    }
                }
            }
            .navigationTitle("ひとを ふやす")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ついか") {
                        onAdd(name.trimmingCharacters(in: .whitespacesAndNewlines), emoji)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// 子どもを選んだあとの画面
struct ProfileHomeView: View {
    let profile: Profile
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(profile.emoji)
                .font(.system(size: 96))
            Text("\(profile.name) さん")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            ForEach(QuizMode.allCases) { mode in
                NavigationLink {
                    QuizView(profile: profile, mode: mode, context: context)
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .frame(minWidth: 240)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint(for: mode))
            }

            Spacer()

            NavigationLink {
                HistoryView(profile: profile)
            } label: {
                Label("きろく（おうちのかたへ）", systemImage: "chart.bar")
            }
            .padding(.bottom, 24)
        }
    }

    private func tint(for mode: QuizMode) -> Color {
        switch mode {
        case .hiragana: return .orange
        case .word: return .pink
        case .picture: return .teal
        }
    }
}
