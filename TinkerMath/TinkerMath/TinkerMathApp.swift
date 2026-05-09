import SwiftUI

@main
struct TinkerMathApp: App {
    @StateObject private var userProgress = UserProgress()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProgress)
        }
    }
}
