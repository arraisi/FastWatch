import Foundation

struct UserPreferences: Codable {
    var defaultProtocol: FastingProtocol = .sixteen8
    var customFastingHours: Double = 16
    var customEatingHours: Double = 8
    var notifyOnMilestones: Bool = true
    var notifyOnGoalReached: Bool = true
    var notifyEatingWindowEnding: Bool = true
    var eatingWindowReminderMinutes: Int = 30
    var hapticsEnabled: Bool = true
    var hapticIntensity: HapticIntensity = .strong
    var overtimeReminder: Bool = true
    var healthKitEnabled: Bool = false
}

enum HapticIntensity: String, Codable {
    case light, strong
}
