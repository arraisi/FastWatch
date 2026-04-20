import SwiftUI
import SwiftData
import WatchKit  // T019: For background refresh handling
import WidgetKit

@main
struct FastWatchApp: App {
    @State private var fastingManager = FastingManager()
    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(fastingManager)
                .onAppear {
                    appDelegate.fastingManager = fastingManager
                }
        }
        .modelContainer(for: CompletedFast.self)
    }
}

// T019, T020: Handle background refresh to start fasting when eating ends
class AppDelegate: NSObject, WKApplicationDelegate {
    var fastingManager: FastingManager?

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                handleRefreshTask(refreshTask)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func handleRefreshTask(_ task: WKApplicationRefreshBackgroundTask) {
        // Check if this is the eating-ended refresh
        if let userInfo = task.userInfo as? [String: Any],
           let action = userInfo["action"] as? String,
           action == "eatingEnded" {
            // T020: Start fasting and reload widget
            fastingManager?.updateState()
            WidgetCenter.shared.reloadAllTimelines()
        }
        task.setTaskCompletedWithSnapshot(false)
    }
}
