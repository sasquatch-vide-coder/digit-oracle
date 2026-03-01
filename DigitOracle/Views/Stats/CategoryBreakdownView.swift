import SwiftUI
import SwiftData
import Charts

struct VesselsView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private var stats: SightingStats {
        StatsCalculator.calculate(from: sightings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !stats.categoryBreakdown.isEmpty {
                    vesselChart
                } else {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.pie",
                        description: Text("Begin divining visions to see thy vessels.")
                    )
                }

                vesselLegend
            }
            .padding()
        }
        .navigationTitle("Vessels")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Vessel Chart

    private var vesselChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Vessel")
                .font(.headline)

            Chart(stats.categoryBreakdown, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Vessel", item.category)
                )
                .foregroundStyle(colorForCategory(item.category))
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(stats.categoryBreakdown.count) * 44)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Vessel Legend

    private var vesselLegend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The Six Vessels")
                .font(.headline)

            ForEach(SightingCategory.allCases) { category in
                let count = stats.categoryBreakdown.first(where: { $0.category.lowercased() == category.rawValue })?.count ?? 0
                HStack(spacing: 12) {
                    Image(systemName: category.iconName)
                        .font(.body)
                        .foregroundColor(category.color)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.displayName)
                            .font(.subheadline.bold())
                        Text(category.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Colors

    private func colorForCategory(_ name: String) -> Color {
        if let cat = SightingCategory(rawValue: name.lowercased()) {
            return cat.color
        }
        return .gray
    }
}
