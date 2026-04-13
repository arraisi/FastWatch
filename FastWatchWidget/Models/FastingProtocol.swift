import Foundation

enum FastingProtocol: String, Codable, CaseIterable, Identifiable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "23:1"
    case twentyFourHour = "24h"
    case thirtySixHour = "36h"
    case fortyEightHour = "48h+"
    case custom = "Custom"

    var id: String { rawValue }

    var fastingDuration: TimeInterval {
        switch self {
        case .sixteen8:       return 16 * 3600
        case .eighteen6:      return 18 * 3600
        case .twenty4:        return 20 * 3600
        case .omad:           return 23 * 3600
        case .twentyFourHour: return 24 * 3600
        case .thirtySixHour:  return 36 * 3600
        case .fortyEightHour: return 48 * 3600
        case .custom:         return 0
        }
    }

    var eatingDuration: TimeInterval? {
        switch self {
        case .sixteen8:       return 8 * 3600
        case .eighteen6:      return 6 * 3600
        case .twenty4:        return 4 * 3600
        case .omad:           return 1 * 3600
        case .twentyFourHour, .thirtySixHour, .fortyEightHour:
            return nil
        case .custom:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .sixteen8:       return "16:8"
        case .eighteen6:      return "18:6"
        case .twenty4:        return "20:4"
        case .omad:           return "OMAD (23:1)"
        case .twentyFourHour: return "24 Hour"
        case .thirtySixHour:  return "36 Hour"
        case .fortyEightHour: return "48+ Hour"
        case .custom:         return "Custom"
        }
    }

    var shortDescription: String {
        switch self {
        case .sixteen8:       return "Most popular IF protocol"
        case .eighteen6:      return "Moderate restriction"
        case .twenty4:        return "Warrior Diet style"
        case .omad:           return "One Meal A Day"
        case .twentyFourHour: return "Full day fast"
        case .thirtySixHour:  return "Extended fast"
        case .fortyEightHour: return "Multi-day fast"
        case .custom:         return "Custom schedule"
        }
    }
}
