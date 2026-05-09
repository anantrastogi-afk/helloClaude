import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userProgress: UserProgress

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                TopicSelectionView()
            }
            .tabItem {
                Label("Practice", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                QuizSetupView()
            }
            .tabItem {
                Label("Quiz", systemImage: "timer")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }
        }
        .tint(.blue)
    }
}
