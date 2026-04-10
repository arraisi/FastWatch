import SwiftUI
import SwiftData

@main
struct FastWatchApp: App {
    @State private var fastingManager = FastingManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(fastingManager)
        }
        .modelContainer(for: CompletedFast.self)
    }
}
