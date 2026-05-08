import Foundation
import Combine

class PracticeViewModel: ObservableObject {
    @Published var problems: [Problem] = []
    @Published var currentIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isAnswerRevealed: Bool = false
    @Published var sessionCorrect: Int = 0
    @Published var sessionAttempted: Int = 0
    @Published var isSessionComplete: Bool = false

    private var userProgress: UserProgress?

    var currentProblem: Problem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }

    var progress: Double {
        guard !problems.isEmpty else { return 0 }
        return Double(currentIndex) / Double(problems.count)
    }

    var isLastProblem: Bool { currentIndex == problems.count - 1 }

    var sessionAccuracy: Double {
        guard sessionAttempted > 0 else { return 0 }
        return Double(sessionCorrect) / Double(sessionAttempted)
    }

    func startSession(grade: Grade, topic: Topic, userProgress: UserProgress) {
        self.userProgress = userProgress
        let pool = ProblemBank.problems(for: grade, topic: topic)
        problems = Array(pool.shuffled().prefix(10))
        reset()
    }

    func startFreeSession(grade: Grade, userProgress: UserProgress) {
        self.userProgress = userProgress
        let pool = ProblemBank.problems(for: grade)
        problems = Array(pool.shuffled().prefix(10))
        reset()
    }

    private func reset() {
        currentIndex = 0
        selectedAnswerIndex = nil
        isAnswerRevealed = false
        sessionCorrect = 0
        sessionAttempted = 0
        isSessionComplete = false
    }

    func selectAnswer(_ index: Int) {
        guard !isAnswerRevealed, let problem = currentProblem else { return }
        selectedAnswerIndex = index
        isAnswerRevealed = true
        sessionAttempted += 1
        let correct = index == problem.correctAnswerIndex
        if correct { sessionCorrect += 1 }
        userProgress?.recordAnswer(problem: problem, isCorrect: correct)
    }

    func advance() {
        if isLastProblem {
            isSessionComplete = true
        } else {
            currentIndex += 1
            selectedAnswerIndex = nil
            isAnswerRevealed = false
        }
    }
}
