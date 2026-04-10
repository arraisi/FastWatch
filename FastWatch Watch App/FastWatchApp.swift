import SwiftUI

@main
struct FastWatchApp: App {
    @State private var fastingManager = FastingManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(fastingManager)
        }
    }
}
