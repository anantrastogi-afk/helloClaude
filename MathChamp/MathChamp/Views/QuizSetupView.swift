import SwiftUI

struct QuizSetupView: View {
    @EnvironmentObject var userProgress: UserProgress
    @StateObject private var quizVM = QuizViewModel()
    @State private var selectedCompetition: Competition = .general
    @State private var showQuiz = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                competitionSection
                settingsCard
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Quiz Mode")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(quizVM: quizVM)
                .environmentObject(userProgress)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.93, green: 0.29, blue: 0.29),
                                 Color(red: 0.97, green: 0.58, blue: 0.19)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text("Competition Quiz")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Timed practice to sharpen\nyour skills under pressure")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var competitionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Competition Format")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(Competition.allCases, id: \.self) { comp in
                    CompetitionOptionCard(
                        competition: comp,
                        isSelected: selectedCompetition == comp
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCompetition = comp
                        }
                    }
                }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz Settings")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                SettingRow(
                    icon: "person.fill",
                    label: "Grade",
                    value: userProgress.selectedGrade.displayName,
                    color: .blue
                )
                Divider().padding(.leading, 44)
                SettingRow(
                    icon: "number",
                    label: "Problems",
                    value: "\(selectedCompetition.quizProblemCount)",
                    color: .purple
                )
                Divider().padding(.leading, 44)
                SettingRow(
                    icon: "clock.fill",
                    label: "Time Limit",
                    value: formatTime(selectedCompetition.quizDuration),
                    color: .orange
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var startButton: some View {
        Button {
            quizVM.setup(
                grade: userProgress.selectedGrade,
                competition: selectedCompetition,
                userProgress: userProgress
            )
            showQuiz = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start Quiz")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.93, green: 0.29, blue: 0.29),
                             Color(red: 0.97, green: 0.58, blue: 0.19)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ seconds: Int) -> String {
        "\(seconds / 60) min"
    }
}

struct CompetitionOptionCard: View {
    let competition: Competition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(competition.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(competition.swiftUIColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(competition.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(competition.description)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? competition.swiftUIColor : Color(.systemGray3))
                    .font(.system(size: 22))
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? competition.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SettingRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(label)
                .font(.system(size: 15, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
