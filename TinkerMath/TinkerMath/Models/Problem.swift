import Foundation

enum Grade: Int, Codable, CaseIterable, Comparable {
    case third = 3
    case fourth = 4
    case fifth = 5

    static func < (lhs: Grade, rhs: Grade) -> Bool { lhs.rawValue < rhs.rawValue }

    var displayName: String {
        switch self {
        case .third: return "3rd Grade"
        case .fourth: return "4th Grade"
        case .fifth: return "5th Grade"
        }
    }

    var emoji: String {
        switch self {
        case .third: return "🌱"
        case .fourth: return "🌿"
        case .fifth: return "🌳"
        }
    }
}

enum Topic: String, Codable, CaseIterable {
    case arithmetic = "Arithmetic"
    case fractions = "Fractions"
    case decimals = "Decimals"
    case geometry = "Geometry"
    case algebra = "Algebra"
    case wordProblems = "Word Problems"
    case numberTheory = "Number Theory"
    case patterns = "Patterns"

    var emoji: String {
        switch self {
        case .arithmetic: return "➕"
        case .fractions: return "½"
        case .decimals: return "·"
        case .geometry: return "📐"
        case .algebra: return "🔡"
        case .wordProblems: return "📝"
        case .numberTheory: return "🔢"
        case .patterns: return "🔄"
        }
    }

    var color: TopicColor {
        switch self {
        case .arithmetic: return .blue
        case .fractions: return .green
        case .decimals: return .orange
        case .geometry: return .purple
        case .algebra: return .red
        case .wordProblems: return .teal
        case .numberTheory: return .indigo
        case .patterns: return .pink
        }
    }
}

enum TopicColor: String {
    case blue, green, orange, purple, red, teal, indigo, pink
}

enum Competition: String, Codable, CaseIterable {
    case mathcounts = "MATHCOUNTS"
    case amc8 = "AMC 8"
    case general = "General"

    var description: String {
        switch self {
        case .mathcounts: return "Sprint & Target style"
        case .amc8: return "25-question AMC format"
        case .general: return "Mixed practice"
        }
    }

    var quizDuration: Int {
        switch self {
        case .mathcounts: return 1800
        case .amc8: return 2400
        case .general: return 900
        }
    }

    var quizProblemCount: Int {
        switch self {
        case .mathcounts: return 15
        case .amc8: return 10
        case .general: return 10
        }
    }

    var emoji: String {
        switch self {
        case .mathcounts: return "🏆"
        case .amc8: return "⭐"
        case .general: return "📚"
        }
    }

    var color: TopicColor {
        switch self {
        case .mathcounts: return .blue
        case .amc8: return .purple
        case .general: return .green
        }
    }
}

enum Difficulty: Int, Codable, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var emoji: String {
        switch self {
        case .easy: return "⚡"
        case .medium: return "🔥"
        case .hard: return "💎"
        }
    }
}

struct Problem: Identifiable, Codable, Equatable {
    let id: UUID
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    let topic: Topic
    let difficulty: Difficulty
    let grade: Grade
    let competition: Competition

    var correctAnswer: String { options[correctAnswerIndex] }

    static func == (lhs: Problem, rhs: Problem) -> Bool { lhs.id == rhs.id }
}
