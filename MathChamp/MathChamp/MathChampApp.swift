import SwiftUI

@main
struct MathChampApp: App {
    @StateObject private var userProgress = UserProgress()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProgress)
        }
    }
}
