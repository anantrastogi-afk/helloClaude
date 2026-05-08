import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userProgress: UserProgress

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overallStatsSection
                topicBreakdownSection
                quizHistorySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    private var overallStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                BigStatCard(
                    title: "Problems Solved",
                    value: "\(userProgress.totalAttempted)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                BigStatCard(
                    title: "Overall Accuracy",
                    value: String(format: "%.0f%%", userProgress.accuracy * 100),
                    icon: "target",
                    color: .green
                )
            }
            HStack(spacing: 12) {
                BigStatCard(
                    title: "Current Streak",
                    value: "🔥 \(userProgress.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                BigStatCard(
                    title: "Best Streak",
                    value: "⭐ \(userProgress.longestStreak)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }

    private var topicBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topic Breakdown")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(Array(Topic.allCases.enumerated()), id: \.offset) { idx, topic in
                    let stat = userProgress.stat(for: topic)
                    TopicStatRow(topic: topic, stat: stat)
                    if idx < Topic.allCases.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var quizHistorySection: some View {
        Group {
            if !userProgress.quizHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quiz History")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 0) {
                        ForEach(Array(userProgress.quizHistory.prefix(10).enumerated()), id: \.offset) { idx, result in
                            QuizHistoryRow(result: result)
                            if idx < min(userProgress.quizHistory.count, 10) - 1 {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                EmptyQuizCard()
            }
        }
    }
}

struct BigStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Spacer()
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct TopicStatRow: View {
    let topic: Topic
    let stat: UserProgress.TopicStat

    var body: some View {
        HStack(spacing: 12) {
            Text(topic.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(topic.swiftUIColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(topic.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer()
                    if stat.attempted > 0 {
                        Text(String(format: "%.0f%%", stat.accuracy * 100))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(accuracyColor)
                    } else {
                        Text("Not started")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if stat.attempted > 0 {
                    ProgressView(value: stat.accuracy)
                        .tint(accuracyColor)
                        .scaleEffect(x: 1, y: 1.8, anchor: .center)
                    Text("\(stat.correct)/\(stat.attempted) correct")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var accuracyColor: Color {
        switch stat.accuracy {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

struct QuizHistoryRow: View {
    let result: UserProgress.QuizResult

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(gradeColor.opacity(0.15))
                Text(result.grade)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(gradeColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.competition?.rawValue ?? "Quiz")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(result.date, style: .date)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score)/\(result.total)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(String(format: "%.0f%%", result.percentage * 100))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var gradeColor: Color {
        switch result.percentage {
        case 0.9...: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}

struct EmptyQuizCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Quizzes Yet")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Text("Take your first timed quiz to see\nyour results here.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
