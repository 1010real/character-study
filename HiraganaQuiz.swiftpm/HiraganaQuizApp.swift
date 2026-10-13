import SwiftUI
import SwiftData

@main
struct HiraganaQuizApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileSelectView()
        }
        .modelContainer(for: [Profile.self, AnswerRecord.self])
    }
}
