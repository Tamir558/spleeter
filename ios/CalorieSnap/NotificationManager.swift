import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if !granted {
                print("Notification permission not granted")
            }
        }
    }

    func scheduleLimitReachedNotification(totalCalories: Double) {
        let content = UNMutableNotificationContent()
        content.title = "חריגה בצריכת קלוריות"
        content.body = "הגעת ל-\(Int(totalCalories)) קלוריות היום. נסה להאט ולהקפיד על התזונה שלך."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
}
