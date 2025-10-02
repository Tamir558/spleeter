import SwiftUI
import UserNotifications

@main
struct CalorieSnapApp: App {
    @StateObject private var tracker = DailyCalorieTracker()

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tracker)
                .onAppear {
                    tracker.refreshIfNeeded()
                }
        }
    }
}
