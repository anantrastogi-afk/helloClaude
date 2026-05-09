import SwiftUI

struct TopicSelectionView: View {
    @EnvironmentObject var userProgress: UserProgress
    @StateObject private var practiceVM = PracticeViewModel()
    @State private var selectedTopic: Topic? = nil
    @State private var showPractice = false
    @State private var selectedCompetition: Competition = .general

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                competitionPicker
                topicGrid
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showPractice) {
            if let topic = selectedTopic {
                PracticeSessionView(topic: topic, practiceVM: practiceVM)
                    .environmentObject(userProgress)
            }
        }
    }

    private var competitionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Competition Style")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(Competition.allCases, id: \.self) { comp in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCompetition = comp
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(comp.emoji)
                            Text(comp.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedCompetition == comp ? comp.swiftUIColor : Color(.systemBackground))
                        .foregroundColor(selectedCompetition == comp ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var topicGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose a Topic")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Topic.allCases, id: \.self) { topic in
                    TopicCard(
                        topic: topic,
                        stat: userProgress.stat(for: topic),
                        problemCount: ProblemBank.problems(
                            for: userProgress.selectedGrade,
                            topic: topic
                        ).count
                    ) {
                        selectedTopic = topic
                        practiceVM.startSession(
                            grade: userProgress.selectedGrade,
                            topic: topic,
                            userProgress: userProgress
                        )
                        showPractice = true
                    }
                }
            }
        }
    }
}

struct TopicCard: View {
    let topic: Topic
    let stat: UserProgress.TopicStat
    let problemCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(topic.emoji)
                        .font(.system(size: 28))
                    Spacer()
                    if stat.attempted > 0 {
                        Text(String(format: "%.0f%%", stat.accuracy * 100))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accuracyColor.opacity(0.15))
                            .foregroundColor(accuracyColor)
                            .clipShape(Capsule())
                    }
                }

                Text(topic.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(problemCount) problems")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)

                if stat.attempted > 0 {
                    ProgressView(value: stat.accuracy)
                        .tint(accuracyColor)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(topic.swiftUIColor.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var accuracyColor: Color {
        switch stat.accuracy {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}
