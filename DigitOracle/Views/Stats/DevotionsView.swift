import SwiftUI
import SwiftData
import Charts

struct DevotionsView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private var stats: SightingStats {
        StatsCalculator.calculate(from: sightings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !stats.rarityBreakdown.isEmpty {
                    devotionChart
                } else {
                    ContentUnavailableView(
                        "The Void Awaits",
                        systemImage: "chart.bar",
                        description: Text("Begin divining visions to see thy devotions.")
                    )
                }

                devotionLegend
            }
            .padding()
        }
        .navigationTitle("Devotions")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Devotion Chart

    private var devotionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Devotion")
                .font(.headline)

            Chart(stats.rarityBreakdown, id: \.rarity) { item in
                BarMark(
                    x: .value("Devotion", Constants.Rarity.label(for: item.rarity)),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(devotionColor(for: item.rarity))
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
        .oracleCard()
    }

    // MARK: - Devotion Legend

    private var devotionLegend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Devotion Tiers")
                .font(.headline)

            ForEach(1...5, id: \.self) { score in
                let count = stats.rarityBreakdown.first(where: { $0.rarity == score })?.count ?? 0
                HStack(spacing: 12) {
                    Circle()
                        .fill(devotionColor(for: score))
                        .frame(width: 12, height: 12)
                        .frame(width: 28)
                    Text(Constants.Rarity.label(for: score))
                        .font(.subheadline)
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .oracleCard()
    }

    // MARK: - Colors

    private func devotionColor(for score: Int) -> Color {
        switch score {
        case 1: .gray
        case 2: .goldPrimary
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
    }
}
