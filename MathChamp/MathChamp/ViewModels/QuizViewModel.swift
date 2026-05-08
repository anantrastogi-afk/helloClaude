import Foundation
import Combine

class QuizViewModel: ObservableObject {
    @Published var problems: [Problem] = []
    @Published var currentIndex: Int = 0
    @Published var answers: [Int: Int] = [:]  // problemIndex -> selectedAnswerIndex
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false

    private var timer: AnyCancellable?
    private var competition: Competition = .general
    private var grade: Grade = .third
    private var userProgress: UserProgress?

    var currentProblem: Problem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }

    var score: Int {
        problems.indices.filter { i in
            answers[i] == problems[i].correctAnswerIndex
        }.count
    }

    var totalProblems: Int { problems.count }

    var progress: Double {
        guard !problems.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(problems.count)
    }

    var timeString: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var isTimeLow: Bool { timeRemaining <= 60 }

    var answeredCount: Int { answers.count }

    func setup(grade: Grade, competition: Competition, userProgress: UserProgress) {
        self.grade = grade
        self.competition = competition
        self.userProgress = userProgress
        problems = ProblemBank.randomProblems(
            grade: grade,
            competition: competition,
            count: competition.quizProblemCount
        )
        timeRemaining = competition.quizDuration
        currentIndex = 0
        answers = [:]
        isRunning = false
        isFinished = false
    }

    func start() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.finish()
                }
            }
    }

    func selectAnswer(_ index: Int) {
        guard isRunning else { return }
        answers[currentIndex] = index
    }

    func goToNext() {
        guard currentIndex < problems.count - 1 else {
            finish()
            return
        }
        currentIndex += 1
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func skipCurrent() {
        goToNext()
    }

    func finish() {
        timer?.cancel()
        isRunning = false
        isFinished = true
        let timeUsed = competition.quizDuration - timeRemaining
        let result = UserProgress.QuizResult(
            id: UUID(),
            competitionRaw: competition.rawValue,
            score: score,
            total: totalProblems,
            timeUsed: timeUsed,
            date: Date()
        )
        userProgress?.recordQuiz(result)
    }

    func answerStatus(for index: Int) -> AnswerStatus {
        guard isFinished else {
            return answers[index] != nil ? .answered : .unanswered
        }
        guard let selected = answers[index] else { return .skipped }
        return selected == problems[index].correctAnswerIndex ? .correct : .incorrect
    }

    enum AnswerStatus {
        case unanswered, answered, correct, incorrect, skipped
    }
}
