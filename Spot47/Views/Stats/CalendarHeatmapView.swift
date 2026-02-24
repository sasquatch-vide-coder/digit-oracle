import SwiftUI
import SwiftData

struct CalendarHeatmapView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @State private var selectedMonth = Date.now

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var sightingsByDay: [Date: Int] {
        StatsCalculator.sightingsByDay(from: sightings)
    }

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [DayItem] {
        let range = calendar.range(of: .day, in: .month, for: selectedMonth) ?? 1..<31
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1 // 0-indexed

        var items: [DayItem] = []

        // Leading blanks
        for _ in 0..<firstWeekday {
            items.append(DayItem(date: nil, day: 0))
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                items.append(DayItem(date: date, day: day))
            }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()
                Text(monthTitle)
                    .font(.title3.bold())
                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(calendar.isDate(selectedMonth, equalTo: .now, toGranularity: .month))
            }
            .padding(.horizontal)

            // Day labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth) { item in
                    if let date = item.date {
                        let count = sightingsByDay[calendar.startOfDay(for: date)] ?? 0
                        VStack(spacing: 2) {
                            Text("\(item.day)")
                                .font(.caption2)
                                .foregroundStyle(calendar.isDateInToday(date) ? .white : .primary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(intensityColor(for: count))
                                .frame(height: 24)
                                .overlay {
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .padding(2)
                        .background(
                            calendar.isDateInToday(date) ? Color.accentColor.opacity(0.3) : .clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensityColor(for: i))
                        .frame(width: 14, height: 14)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func intensityColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.secondary.opacity(0.15)
        case 1: return Color.green.opacity(0.4)
        case 2: return Color.green.opacity(0.6)
        case 3: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }
}

private struct DayItem: Identifiable {
    let id = UUID()
    let date: Date?
    let day: Int
}
