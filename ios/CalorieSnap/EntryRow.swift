import SwiftUI

struct EntryRow: View {
    let entry: CalorieEntry

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.foodName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text(entry.formattedTimestamp)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(entry.formattedCalories)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
    }
}

struct EntryRow_Previews: PreviewProvider {
    static var previews: some View {
        EntryRow(
            entry: CalorieEntry(
                id: UUID(),
                foodName: "סלט קוסקוס",
                estimatedCalories: 420,
                timestamp: Date(),
                imageData: nil
            )
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
