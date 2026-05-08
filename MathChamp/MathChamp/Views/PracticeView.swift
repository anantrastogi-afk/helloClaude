import SwiftUI

struct PracticeSessionView: View {
    let topic: Topic
    @ObservedObject var practiceVM: PracticeViewModel
    @EnvironmentObject var userProgress: UserProgress
    @Environment(\.dismiss) private var dismiss

    private let answerLabels = ["A", "B", "C", "D"]

    var body: some View {
        NavigationStack {
            Group {
                if practiceVM.isSessionComplete {
                    sessionSummaryView
                } else if let problem = practiceVM.currentProblem {
                    problemView(problem: problem)
                } else {
                    emptyView
                }
            }
            .navigationTitle(topic.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 15, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(practiceVM.currentIndex + 1)/\(practiceVM.problems.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func problemView(problem: Problem) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                progressBar

                difficultyBadge(problem: problem)

                questionCard(problem: problem)

                answerButtons(problem: problem)

                if practiceVM.isAnswerRevealed {
                    ExplanationCard(problem: problem,
                                    selectedIndex: practiceVM.selectedAnswerIndex ?? 0)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    nextButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .animation(.spring(response: 0.4), value: practiceVM.isAnswerRevealed)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: practiceVM.progress)
                .tint(topic.swiftUIColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }

    private func difficultyBadge(problem: Problem) -> some View {
        HStack {
            Label(problem.difficulty.displayName, systemImage: "flame.fill")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(problem.difficulty.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(problem.difficulty.swiftUIColor.opacity(0.12))
                .clipShape(Capsule())

            Label(problem.competition.rawValue, systemImage: "rosette")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(problem.competition.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(problem.competition.swiftUIColor.opacity(0.12))
                .clipShape(Capsule())

            Spacer()
        }
    }

    private func questionCard(problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(problem.question)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
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
                    state: buttonState(for: i, problem: problem)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        practiceVM.selectAnswer(i)
                    }
                }
            }
        }
    }

    private func buttonState(for index: Int, problem: Problem) -> AnswerButton.AnswerButtonState {
        guard practiceVM.isAnswerRevealed else {
            return practiceVM.selectedAnswerIndex == index ? .selected : .idle
        }
        if index == problem.correctAnswerIndex { return .correct }
        if index == practiceVM.selectedAnswerIndex { return .incorrect }
        return .idle
    }

    private var nextButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                practiceVM.advance()
            }
        } label: {
            Text(practiceVM.isLastProblem ? "See Results" : "Next Question →")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(topic.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var sessionSummaryView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text(summaryEmoji)
                    .font(.system(size: 64))
                Text(summaryTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(summarySubtitle)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ScoreRing(score: practiceVM.sessionCorrect,
                      total: practiceVM.sessionAttempted,
                      color: topic.swiftUIColor)

            VStack(spacing: 12) {
                Button {
                    practiceVM.startFreeSession(grade: userProgress.selectedGrade,
                                                userProgress: userProgress)
                } label: {
                    Text("Practice More")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(topic.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var summaryEmoji: String {
        switch practiceVM.sessionAccuracy {
        case 0.9...: return "🏆"
        case 0.7..<0.9: return "⭐"
        case 0.5..<0.7: return "💪"
        default: return "📖"
        }
    }

    private var summaryTitle: String {
        switch practiceVM.sessionAccuracy {
        case 0.9...: return "Outstanding!"
        case 0.7..<0.9: return "Great Work!"
        case 0.5..<0.7: return "Keep Going!"
        default: return "Keep Practicing!"
        }
    }

    private var summarySubtitle: String {
        "\(practiceVM.sessionCorrect) out of \(practiceVM.sessionAttempted) correct"
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Problems Found",
            systemImage: "questionmark.circle",
            description: Text("Try a different topic or grade level.")
        )
    }
}

struct ScoreRing: View {
    let score: Int
    let total: Int
    let color: Color

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 16)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8), value: fraction)
            VStack(spacing: 4) {
                Text("\(score)/\(total)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 160, height: 160)
    }
}
