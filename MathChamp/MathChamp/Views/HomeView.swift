import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userProgress: UserProgress
    @State private var showGradePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                gradeSection
                statsRow
                quickActionsSection
                recentActivitySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MathChamp 🏆")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Ready to compete?")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            streakBadge
        }
        .padding(.top, 16)
    }

    private var streakBadge: some View {
        VStack(spacing: 2) {
            Text("🔥")
                .font(.system(size: 24))
            Text("\(userProgress.currentStreak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text("streak")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var gradeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Grade")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    GradePill(grade: grade, isSelected: userProgress.selectedGrade == grade) {
                        withAnimation(.spring(response: 0.3)) {
                            userProgress.selectedGrade = grade
                        }
                    }
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatMiniCard(
                title: "Solved",
                value: "\(userProgress.totalAttempted)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
            StatMiniCard(
                title: "Accuracy",
                value: String(format: "%.0f%%", userProgress.accuracy * 100),
                icon: "target",
                color: .green
            )
            StatMiniCard(
                title: "Best Streak",
                value: "\(userProgress.longestStreak)",
                icon: "flame.fill",
                color: .orange
            )
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Start")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            NavigationLink {
                TopicSelectionView()
            } label: {
                QuickActionCard(
                    title: "Practice Problems",
                    subtitle: "Choose a topic and grade",
                    icon: "books.vertical.fill",
                    gradient: [Color(red: 0.27, green: 0.55, blue: 0.93),
                               Color(red: 0.35, green: 0.34, blue: 0.84)]
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                QuizSetupView()
            } label: {
                QuickActionCard(
                    title: "Take a Quiz",
                    subtitle: "Timed competition practice",
                    icon: "timer",
                    gradient: [Color(red: 0.93, green: 0.29, blue: 0.29),
                               Color(red: 0.97, green: 0.58, blue: 0.19)]
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var recentActivitySection: some View {
        Group {
            if !userProgress.recentResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Activity")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 0) {
                        ForEach(Array(userProgress.recentResults.prefix(5))) { result in
                            RecentResultRow(result: result)
                            if result.id != userProgress.recentResults.prefix(5).last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}

// MARK: - Sub-components

struct GradePill: View {
    let grade: Grade
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(grade.emoji)
                Text(grade.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : .black.opacity(0.05),
                    radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
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

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct RecentResultRow: View {
    let result: UserProgress.ProblemResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.isCorrect ? .green : .red)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(result.topic?.rawValue ?? "Unknown")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(result.date, style: .relative)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(result.isCorrect ? "Correct" : "Incorrect")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(result.isCorrect ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
