import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var tracker: DailyCalorieTracker
    @State private var isPresentingCamera = false
    @State private var pendingImage: UIImage?
    @State private var isAnalyzing = false
    @State private var alertMessage: String?

    private let estimator = FoodCalorieEstimator()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                summaryCard
                captureButton
                entriesList
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Calorie Snap")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isPresentingCamera) {
                CameraCaptureView(image: $pendingImage)
            }
            .onChange(of: pendingImage) { image in
                guard let image else { return }
                analyze(image: image)
            }
            .alert(item: Binding(
                get: {
                    alertMessage.map { AlertMessage(message: $0) }
                },
                set: { newValue in
                    alertMessage = newValue?.message
                }
            )) { alert in
                Alert(title: Text("תוצאה"), message: Text(alert.message), dismissButton: .default(Text("אישור")))
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("סך הכל היום")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("\(Int(tracker.totalCalories)) קל׳")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(tracker.totalCalories >= 1_800 ? .red : .primary)
            Text("נותרו \(Int(tracker.remainingCalories)) קל׳ עד 1800")
                .font(.title3)
                .foregroundColor(.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
    }

    private var captureButton: some View {
        Button(action: {
            isPresentingCamera = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                Text(isAnalyzing ? "מנתח..." : "צלם ארוחה חדשה")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .disabled(isAnalyzing)
        .buttonStyle(LargePrimaryButtonStyle())
    }

    private var entriesList: some View {
        Group {
            if tracker.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("עדיין לא צילמת ארוחה היום")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(tracker.entries) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete(perform: tracker.deleteEntries)
                }
                .listStyle(.insetGrouped)
            }
        }
        .animation(.spring(), value: tracker.entries)
    }

    private func analyze(image: UIImage) {
        isAnalyzing = true
        estimator.estimateCalories(for: image) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                pendingImage = nil
                switch result {
                case let .success(estimate):
                    tracker.addEntry(
                        foodName: estimate.foodName,
                        estimatedCalories: estimate.calories,
                        image: image
                    )
                    alertMessage = "\(estimate.foodName) ≈ \(Int(estimate.calories)) קל׳"
                case let .failure(error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DailyCalorieTracker())
    }
}
