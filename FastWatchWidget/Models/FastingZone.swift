import SwiftUI

enum FastingZone: String {
    case fed = "Fed State"
    case earlyFasting = "Early Fasting"
    case fatBurning = "Fat Burning"
    case ketosis = "Ketosis"
    case deepKetosis = "Deep Ketosis"
    case autophagy = "Autophagy"

    var color: Color {
        switch self {
        case .fed:          return .green
        case .earlyFasting: return .green
        case .fatBurning:   return .teal
        case .ketosis:      return .blue
        case .deepKetosis:  return .indigo
        case .autophagy:    return .purple
        }
    }

    var icon: String {
        switch self {
        case .fed:          return "fork.knife"
        case .earlyFasting: return "flame"
        case .fatBurning:   return "flame.fill"
        case .ketosis:      return "bolt.fill"
        case .deepKetosis:  return "bolt.circle.fill"
        case .autophagy:    return "arrow.3.trianglepath"
        }
    }

    var description: String {
        switch self {
        case .fed:          return "Digesting food, insulin elevated"
        case .earlyFasting: return "Blood sugar normalizing"
        case .fatBurning:   return "Body switching to fat for fuel"
        case .ketosis:      return "Producing ketones for energy"
        case .deepKetosis:  return "Peak fat oxidation"
        case .autophagy:    return "Cellular cleanup and renewal"
        }
    }

    static func zone(for elapsedHours: Double) -> FastingZone {
        switch elapsedHours {
        case ..<4:    return .fed
        case ..<8:    return .earlyFasting
        case ..<12:   return .fatBurning
        case ..<18:   return .ketosis
        case ..<24:   return .deepKetosis
        default:      return .autophagy
        }
    }
}
