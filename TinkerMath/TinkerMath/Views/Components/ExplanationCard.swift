import SwiftUI

struct ExplanationCard: View {
    let problem: Problem
    let selectedIndex: Int

    private var isCorrect: Bool { selectedIndex == problem.correctAnswerIndex }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .foregroundColor(isCorrect ? .green : .orange)
                    .font(.system(size: 18))
                Text(isCorrect ? "Great job! 🎉" : "Here's how to solve it:")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isCorrect ? .green : .orange)
            }

            if !isCorrect {
                HStack(spacing: 6) {
                    Text("Correct answer:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(problem.correctAnswer)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
            }

            Text(problem.explanation)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCorrect ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1.5)
        )
    }
}
