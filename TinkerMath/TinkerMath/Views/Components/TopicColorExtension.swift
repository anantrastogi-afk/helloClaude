import SwiftUI

extension TopicColor {
    var swiftUIColor: Color {
        switch self {
        case .blue:   return Color(red: 0.27, green: 0.55, blue: 0.93)
        case .green:  return Color(red: 0.18, green: 0.80, blue: 0.44)
        case .orange: return Color(red: 0.97, green: 0.58, blue: 0.19)
        case .purple: return Color(red: 0.56, green: 0.35, blue: 0.87)
        case .red:    return Color(red: 0.93, green: 0.29, blue: 0.29)
        case .teal:   return Color(red: 0.20, green: 0.69, blue: 0.69)
        case .indigo: return Color(red: 0.35, green: 0.34, blue: 0.84)
        case .pink:   return Color(red: 0.96, green: 0.41, blue: 0.65)
        }
    }
}

extension Topic {
    var swiftUIColor: Color { color.swiftUIColor }
}

extension Competition {
    var swiftUIColor: Color { color.swiftUIColor }
}

extension Difficulty {
    var swiftUIColor: Color {
        switch self {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }
}
