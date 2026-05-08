import Foundation
import Combine

class UserProgress: ObservableObject {
    @Published var selectedGrade: Grade = .third
    @Published var totalAttempted: Int = 0
    @Published var totalCorrect: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastPracticeDate: Date?
    @Published var topicStats: [String: TopicStat] = [:]
    @Published var recentResults: [ProblemResult] = []
    @Published var quizHistory: [QuizResult] = []

    struct TopicStat: Codable {
        var attempted: Int = 0
        var correct: Int = 0
        var accuracy: Double {
            guard attempted > 0 else { return 0 }
            return Double(correct) / Double(attempted)
        }
    }

    struct ProblemResult: Identifiable, Codable {
        let id: UUID
        let problemId: UUID
        let isCorrect: Bool
        let date: Date
        let topicRaw: String
        var topic: Topic? { Topic(rawValue: topicRaw) }
    }

    struct QuizResult: Identifiable, Codable {
        let id: UUID
        let competitionRaw: String
        let score: Int
        let total: Int
        let timeUsed: Int
        let date: Date
        var competition: Competition? { Competition(rawValue: competitionRaw) }
        var percentage: Double { Double(score) / Double(total) }
        var grade: String {
            switch percentage {
            case 0.9...: return "A+"
            case 0.8..<0.9: return "A"
            case 0.7..<0.8: return "B"
            case 0.6..<0.7: return "C"
            default: return "Try Again"
            }
        }
    }

    private let storageKey = "mathchamp_v1_progress"

    init() {
        load()
        checkStreakReset()
    }

    var accuracy: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempted)
    }

    func stat(for topic: Topic) -> TopicStat {
        topicStats[topic.rawValue] ?? TopicStat()
    }

    func recordAnswer(problem: Problem, isCorrect: Bool) {
        totalAttempted += 1
        if isCorrect { totalCorrect += 1 }

        var s = topicStats[problem.topic.rawValue] ?? TopicStat()
        s.attempted += 1
        if isCorrect { s.correct += 1 }
        topicStats[problem.topic.rawValue] = s

        let result = ProblemResult(
            id: UUID(), problemId: problem.id,
            isCorrect: isCorrect, date: Date(),
            topicRaw: problem.topic.rawValue
        )
        recentResults.insert(result, at: 0)
        if recentResults.count > 100 { recentResults = Array(recentResults.prefix(100)) }

        if isCorrect {
            currentStreak += 1
            if currentStreak > longestStreak { longestStreak = currentStreak }
        } else {
            currentStreak = 0
        }
        lastPracticeDate = Date()
        save()
    }

    func recordQuiz(_ result: QuizResult) {
        quizHistory.insert(result, at: 0)
        if quizHistory.count > 30 { quizHistory = Array(quizHistory.prefix(30)) }
        save()
    }

    private func checkStreakReset() {
        guard let last = lastPracticeDate else { return }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        if days > 1 { currentStreak = 0 }
    }

    private func save() {
        let data = StorageData(
            selectedGradeRaw: selectedGrade.rawValue,
            totalAttempted: totalAttempted, totalCorrect: totalCorrect,
            currentStreak: currentStreak, longestStreak: longestStreak,
            lastPracticeDate: lastPracticeDate,
            topicStats: topicStats,
            recentResults: recentResults, quizHistory: quizHistory
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        guard let raw = UserDefaults.standard.data(forKey: storageKey),
              let data = try? JSONDecoder().decode(StorageData.self, from: raw) else { return }
        selectedGrade = Grade(rawValue: data.selectedGradeRaw) ?? .third
        totalAttempted = data.totalAttempted
        totalCorrect = data.totalCorrect
        currentStreak = data.currentStreak
        longestStreak = data.longestStreak
        lastPracticeDate = data.lastPracticeDate
        topicStats = data.topicStats
        recentResults = data.recentResults
        quizHistory = data.quizHistory
    }

    private struct StorageData: Codable {
        var selectedGradeRaw: Int
        var totalAttempted: Int
        var totalCorrect: Int
        var currentStreak: Int
        var longestStreak: Int
        var lastPracticeDate: Date?
        var topicStats: [String: TopicStat]
        var recentResults: [ProblemResult]
        var quizHistory: [QuizResult]
    }
}
