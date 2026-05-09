import SwiftUI

struct QuizView: View {
    @ObservedObject var quizVM: QuizViewModel
    @EnvironmentObject var userProgress: UserProgress
    @Environment(\.dismiss) private var dismiss

    private let answerLabels = ["A", "B", "C", "D"]

    var body: some View {
        NavigationStack {
            Group {
                if quizVM.isFinished {
                    QuizResultsView(quizVM: quizVM) { dismiss() }
                } else if let problem = quizVM.currentProblem {
                    quizProblemView(problem: problem)
                } else {
                    startView
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if !quizVM.isRunning && !quizVM.isFinished {
                quizVM.start()
            }
        }
    }

    private var startView: some View {
        VStack(spacing: 20) {
            Text("Loading quiz…")
                .font(.system(size: 18, design: .rounded))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func quizProblemView(problem: Problem) -> some View {
        VStack(spacing: 0) {
            quizTopBar
            ScrollView {
                VStack(spacing: 16) {
                    quizProgressBar
                    questionBubble(problem: problem)
                    answerButtons(problem: problem)
                    navigationRow
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
    }

    private var quizTopBar: some View {
        HStack(spacing: 16) {
            Button {
                quizVM.finish()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }

            Spacer()

            TimerView(timeString: quizVM.timeString, isLow: quizVM.isTimeLow)

            Spacer()

            Text("\(quizVM.currentIndex + 1)/\(quizVM.totalProblems)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var quizProgressBar: some View {
        ProgressView(value: quizVM.progress)
            .tint(.red)
            .scaleEffect(x: 1, y: 2, anchor: .center)
    }

    private func questionBubble(problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(problem.topic.rawValue, systemImage: "tag.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(problem.topic.swiftUIColor)
                Spacer()
                Text(problem.difficulty.emoji + " " + problem.difficulty.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(problem.difficulty.swiftUIColor)
            }
            Text(problem.question)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func answerButtons(problem: Problem) -> some View {
        VStack(spacing: 10) {
            ForEach(0..<problem.options.count, id: \.self) { i in
                AnswerButton(
                    label: answerLabels[i],
                    text: problem.options[i],
                    state: quizAnswerState(for: i)
                ) {
                    quizVM.selectAnswer(i)
                }
            }
        }
    }

    private func quizAnswerState(for index: Int) -> AnswerButton.AnswerButtonState {
        if let selected = quizVM.answers[quizVM.currentIndex], selected == index {
            return .selected
        }
        return .idle
    }

    private var navigationRow: some View {
        HStack(spacing: 12) {
            if quizVM.currentIndex > 0 {
                Button {
                    quizVM.goToPrevious()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 48, height: 48)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button {
                quizVM.skipCurrent()
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                if quizVM.currentIndex == quizVM.totalProblems - 1 {
                    quizVM.finish()
                } else {
                    quizVM.goToNext()
                }
            } label: {
                Text(quizVM.currentIndex == quizVM.totalProblems - 1 ? "Finish" : "Next")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }
}

struct TimerView: View {
    let timeString: String
    let isLow: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
            Text(timeString)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
        .foregroundColor(isLow ? .white : .primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(isLow ? Color.red : Color(.systemGray5))
        .clipShape(Capsule())
        .animation(.easeInOut, value: isLow)
    }
}

struct QuizResultsView: View {
    @ObservedObject var quizVM: QuizViewModel
    let onDismiss: () -> Void
    @State private var showReview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                VStack(spacing: 10) {
                    Text(scoreEmoji)
                        .font(.system(size: 64))
                    Text("Quiz Complete!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text(gradeMessage)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                }

                ScoreRing(
                    score: quizVM.score,
                    total: quizVM.totalProblems,
                    color: .red
                )

                statsCards

                reviewSection

                VStack(spacing: 12) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var scoreEmoji: String {
        let pct = Double(quizVM.score) / Double(quizVM.totalProblems)
        switch pct {
        case 0.9...: return "🏆"
        case 0.8..<0.9: return "🥇"
        case 0.7..<0.8: return "🥈"
        case 0.6..<0.7: return "🥉"
        default: return "📖"
        }
    }

    private var gradeMessage: String {
        let pct = Double(quizVM.score) / Double(quizVM.totalProblems)
        switch pct {
        case 0.9...: return "Amazing — competition ready! 🎉"
        case 0.7..<0.9: return "Great performance! Keep it up."
        case 0.5..<0.7: return "Good effort! Review and try again."
        default: return "Practice makes perfect. Don't give up!"
        }
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            ResultStatCard(title: "Score", value: "\(quizVM.score)/\(quizVM.totalProblems)", color: .blue)
            ResultStatCard(title: "Time Used", value: formatTime(quizDuration - quizVM.timeRemaining), color: .orange)
            ResultStatCard(title: "Answered", value: "\(quizVM.answeredCount)/\(quizVM.totalProblems)", color: .green)
        }
        .padding(.horizontal, 20)
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Problem Review")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(quizVM.problems.indices, id: \.self) { i in
                    ReviewRow(
                        index: i,
                        problem: quizVM.problems[i],
                        status: quizVM.answerStatus(for: i),
                        selectedAnswer: quizVM.answers[i]
                    )
                    if i < quizVM.problems.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private var quizDuration: Int {
        if let comp = quizVM.problems.first?.competition {
            return comp.quizDuration
        }
        return 900
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ResultStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct ReviewRow: View {
    let index: Int
    let problem: Problem
    let status: QuizViewModel.AnswerStatus
    let selectedAnswer: Int?

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.question)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(2)
                if case .incorrect = status, let sel = selectedAnswer {
                    Text("Your answer: \(problem.options[sel])")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.red)
                    Text("Correct: \(problem.correctAnswer)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.green)
                } else if case .skipped = status {
                    Text("Skipped — answer: \(problem.correctAnswer)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .correct:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 22))
        case .incorrect:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.system(size: 22))
        case .skipped, .unanswered:
            Image(systemName: "minus.circle.fill").foregroundColor(.secondary).font(.system(size: 22))
        default:
            Image(systemName: "circle").foregroundColor(.secondary).font(.system(size: 22))
        }
    }
}
