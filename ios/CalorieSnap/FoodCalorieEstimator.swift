import Foundation
import Vision
import UIKit

enum EstimationError: LocalizedError {
    case classificationUnavailable
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .classificationUnavailable:
            return "לא ניתן היה לזהות את המזון בתמונה. נסה שוב מזווית אחרת."
        case .imageProcessingFailed:
            return "אירעה שגיאה בעת עיבוד התמונה."
        }
    }
}

struct FoodCalorieEstimate {
    let foodName: String
    let calories: Double
}

final class FoodCalorieEstimator {
    private let queue = DispatchQueue(label: "calorie_estimator_queue")
    private lazy var request: VNClassifyImageRequest = {
        VNClassifyImageRequest()
    }()

    private let calorieLookup: [String: Double] = [
        "salad": 180,
        "pizza": 285,
        "hamburger": 354,
        "sandwich": 320,
        "sushi": 300,
        "pasta": 400,
        "cake": 430,
        "apple": 95,
        "banana": 105,
        "fries": 365
    ]

    func estimateCalories(for image: UIImage, completion: @escaping (Result<FoodCalorieEstimate, Error>) -> Void) {
        queue.async {
            guard let cgImage = image.cgImage else {
                completion(.failure(EstimationError.imageProcessingFailed))
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([self.request])
                guard let observations = self.request.results as? [VNClassificationObservation], let best = observations.first else {
                    completion(.failure(EstimationError.classificationUnavailable))
                    return
                }

                let normalizedIdentifier = best.identifier.lowercased()
                let calorieValue = self.calorieLookup.first { normalizedIdentifier.contains($0.key) }?.value ?? self.heuristicCalories(forConfidence: best.confidence)

                let estimate = FoodCalorieEstimate(
                    foodName: self.localizedName(for: best.identifier),
                    calories: calorieValue
                )
                completion(.success(estimate))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func heuristicCalories(forConfidence confidence: VNConfidence) -> Double {
        let base = 250.0
        let variability = 200.0 * Double(1 - confidence)
        return max(120, base + variability)
    }

    private func localizedName(for identifier: String) -> String {
        let lower = identifier.lowercased()
        if lower.contains("salad") { return "סלט" }
        if lower.contains("pizza") { return "פיצה" }
        if lower.contains("hamburger") { return "המבורגר" }
        if lower.contains("sandwich") { return "כריך" }
        if lower.contains("sushi") { return "סושי" }
        if lower.contains("pasta") { return "פסטה" }
        if lower.contains("cake") { return "עוגה" }
        if lower.contains("apple") { return "תפוח" }
        if lower.contains("banana") { return "בננה" }
        if lower.contains("fries") { return "צ׳יפס" }
        return identifier
    }
}
