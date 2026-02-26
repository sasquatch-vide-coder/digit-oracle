import SwiftUI
import SwiftData
import Charts

struct CategoryBreakdownView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private var stats: SightingStats {
        StatsCalculator.calculate(from: sightings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !stats.categoryBreakdown.isEmpty {
                    categoryChart
                }
                if !stats.rarityBreakdown.isEmpty {
                    rarityChart
                }
                if stats.categoryBreakdown.isEmpty && stats.rarityBreakdown.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.pie",
                        description: Text("Start capturing sightings to see breakdowns.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Breakdowns")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Category Chart

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)

            Chart(stats.categoryBreakdown, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Category", item.category)
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

    // MARK: - Rarity Chart

    private var rarityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Rarity")
                .font(.headline)

            Chart(stats.rarityBreakdown, id: \.rarity) { item in
                BarMark(
                    x: .value("Rarity", Constants.Rarity.label(for: item.rarity)),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(rarityColor(for: item.rarity))
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
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

    private func rarityColor(for score: Int) -> Color {
        switch score {
        case 1: .gray
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
    }
}
