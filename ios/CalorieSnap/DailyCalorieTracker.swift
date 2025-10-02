import Combine
import Foundation
import UIKit

final class DailyCalorieTracker: ObservableObject {
    @Published private(set) var entries: [CalorieEntry] = [] {
        didSet {
            persistEntries()
        }
    }

    private let dailyLimit: Double = 1_800
    private let storageKey = "calorie_entries"
    private let calendar = Calendar.current

    var totalCalories: Double {
        entries.reduce(0) { $0 + $1.estimatedCalories }
    }

    var remainingCalories: Double {
        max(dailyLimit - totalCalories, 0)
    }

    init() {
        loadEntries()
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        guard let firstDate = entries.first?.timestamp else { return }
        let currentPeriodStart = startOfCurrentTrackingPeriod()
        if firstDate < currentPeriodStart {
            entries = []
        }
    }

    func addEntry(foodName: String, estimatedCalories: Double, image: UIImage?) {
        refreshIfNeeded()

        let entry = CalorieEntry(
            id: UUID(),
            foodName: foodName,
            estimatedCalories: estimatedCalories,
            timestamp: Date(),
            imageData: image?.jpegData(compressionQuality: 0.7)
        )

        entries.insert(entry, at: 0)
        if totalCalories >= dailyLimit {
            NotificationManager.shared.scheduleLimitReachedNotification(totalCalories: totalCalories)
        }
    }

    func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    private func loadEntries() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedEntries = try? JSONDecoder().decode([CalorieEntry].self, from: data)
        else {
            entries = []
            return
        }

        entries = savedEntries.filter { $0.timestamp >= startOfCurrentTrackingPeriod() }
    }

    private func persistEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func startOfCurrentTrackingPeriod() -> Date {
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        if let hour = components.hour, hour < 6 {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: now) else {
                return now
            }
            components = calendar.dateComponents([.year, .month, .day], from: previousDay)
        }

        components.hour = 6
        components.minute = 0
        components.second = 0

        return calendar.date(from: components) ?? now
    }
}

struct CalorieEntry: Identifiable, Codable {
    let id: UUID
    let foodName: String
    let estimatedCalories: Double
    let timestamp: Date
    let imageData: Data?

    var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    var formattedCalories: String {
        "\(Int(estimatedCalories)) קל׳"
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "he_IL")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
