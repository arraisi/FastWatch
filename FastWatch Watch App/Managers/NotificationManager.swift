import Foundation
import UserNotifications
import WatchKit

class NotificationManager {
    // MARK: - Notification Identifiers

    private static let fastingIdentifiers = [
        "fasting-goal-reached",
        "fasting-milestone-25",
        "fasting-milestone-50",
        "fasting-milestone-75",
        "fasting-overtime-reminder"
    ]

    private static let eatingIdentifiers = [
        "eating-window-ending"
    ]

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleGoalNotification(at date: Date, protocolName: String) {
        requestPermission()

        let content = UNMutableNotificationContent()
        content.title = "Fast Complete!"
        content.body = "You did it! \(protocolName) fast complete!"
        content.sound = .default

        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "fasting-goal-reached",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleMilestoneNotifications(startTime: Date, duration: TimeInterval) {
        let milestones: [(Double, String)] = [
            (0.25, "Quarter of the way!"),
            (0.50, "Halfway there!"),
            (0.75, "Almost there!"),
        ]

        for (fraction, message) in milestones {
            let triggerDate = startTime.addingTimeInterval(duration * fraction)
            let interval = triggerDate.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let hours = Int(duration * fraction) / 3600

            let content = UNMutableNotificationContent()
            content.title = message
            content.body = "\(hours)h done."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "fasting-milestone-\(Int(fraction * 100))",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    func scheduleEatingWindowReminder(at date: Date, minutesLeft: Int) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Eating Window Closing"
        content.body = "Eating window closes in \(minutesLeft) min."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "eating-window-ending",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleOvertimeReminder(startTime: Date, targetDuration: TimeInterval) {
        let overtimeDate = startTime.addingTimeInterval(targetDuration * 2)
        let interval = overtimeDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let hours = Int(targetDuration * 2) / 3600

        let content = UNMutableNotificationContent()
        content.title = "Still fasting?"
        content.body = "\(hours)h and counting. Tap to check in."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "fasting-overtime-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Category-Specific Cancellation

    func cancelFastingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: Self.fastingIdentifiers
        )
    }

    func cancelEatingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: Self.eatingIdentifiers
        )
    }

    // MARK: - Delivered Notification Cleanup

    func removeDeliveredFastingNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: Self.fastingIdentifiers
        )
    }

    func removeDeliveredEatingNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: Self.eatingIdentifiers
        )
    }

    func playSuccessHaptic() {
        WKInterfaceDevice.current().play(.success)
    }
}
