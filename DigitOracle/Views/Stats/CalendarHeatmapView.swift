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
        ScrollView {
            VStack(spacing: 24) {
                // Yearly heatmap
                YearlyHeatmapSection(sightingsByDay: sightingsByDay)

                Divider()
                    .padding(.horizontal)

                // Monthly detail
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
                }
            }
            .padding(.top)
        }
        .navigationTitle("Sacred Calendar")
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
        case 1: return Color.goldPrimary.opacity(0.4)
        case 2: return Color.goldPrimary.opacity(0.6)
        case 3: return Color.goldPrimary.opacity(0.8)
        default: return Color.goldPrimary
        }
    }
}

// MARK: - Yearly Heatmap

private struct YearlyHeatmapSection: View {
    let sightingsByDay: [Date: Int]

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    private let dayLabels = ["", "M", "", "W", "", "F", ""]

    private var currentYear: Int {
        calendar.component(.year, from: .now)
    }

    private var yearStart: Date {
        calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
    }

    private var yearTotal: Int {
        sightingsByDay.reduce(0) { total, entry in
            let year = calendar.component(.year, from: entry.key)
            return year == currentYear ? total + entry.value : total
        }
    }

    /// Builds a grid of weeks (columns) × weekdays (rows) for the current year
    private var weekColumns: [[Date?]] {
        let today = calendar.startOfDay(for: .now)
        let startWeekday = calendar.component(.weekday, from: yearStart) - 1 // 0 = Sunday

        // Find the last day to show (today or Dec 31, whichever is earlier)
        let yearEnd = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))!
        let lastDay = min(today, yearEnd)

        let totalDays = calendar.dateComponents([.day], from: yearStart, to: lastDay).day! + 1
        let totalSlots = startWeekday + totalDays
        let weekCount = (totalSlots + 6) / 7

        var weeks: [[Date?]] = []

        for week in 0..<weekCount {
            var days: [Date?] = []
            for dow in 0..<7 {
                let slotIndex = week * 7 + dow
                let dayOffset = slotIndex - startWeekday
                if dayOffset < 0 || dayOffset >= totalDays {
                    days.append(nil)
                } else {
                    days.append(calendar.date(byAdding: .day, value: dayOffset, to: yearStart))
                }
            }
            weeks.append(days)
        }

        return weeks
    }

    /// Month labels positioned above the correct week columns
    private var monthMarkers: [(label: String, weekIndex: Int)] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        var markers: [(String, Int)] = []

        for month in 1...12 {
            guard let firstOfMonth = calendar.date(from: DateComponents(year: currentYear, month: month, day: 1)) else { continue }
            // Only show months that have started
            if firstOfMonth > Date.now { break }

            let dayOffset = calendar.dateComponents([.day], from: yearStart, to: firstOfMonth).day!
            let startWeekday = calendar.component(.weekday, from: yearStart) - 1
            let weekIndex = (startWeekday + dayOffset) / 7
            markers.append((months[month - 1], weekIndex))
        }

        return markers
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("\(String(currentYear))")
                    .font(.title3.bold())
                Spacer()
                Text("\(yearTotal) visions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Heatmap grid
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Month labels row
                    monthLabelsRow

                    // Grid with day-of-week labels
                    HStack(alignment: .top, spacing: 0) {
                        // Day-of-week labels
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                Text(dayLabels[row])
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16, height: cellSize)
                            }
                        }

                        // Week columns
                        HStack(spacing: cellSpacing) {
                            ForEach(0..<weekColumns.count, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if let date = weekColumns[weekIndex][dayIndex] {
                                            let count = sightingsByDay[calendar.startOfDay(for: date)] ?? 0
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(intensityColor(for: count))
                                                .frame(width: cellSize, height: cellSize)
                                        } else {
                                            Color.clear
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensityColor(for: i))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var monthLabelsRow: some View {
        let markers = monthMarkers
        let totalWidth = CGFloat(weekColumns.count) * (cellSize + cellSpacing) - cellSpacing
        let dayLabelWidth: CGFloat = 16

        return ZStack(alignment: .leading) {
            Color.clear
                .frame(width: totalWidth + dayLabelWidth, height: 16)

            ForEach(0..<markers.count, id: \.self) { i in
                let xOffset = dayLabelWidth + CGFloat(markers[i].weekIndex) * (cellSize + cellSpacing)
                Text(markers[i].label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .offset(x: xOffset)
            }
        }
        .padding(.horizontal)
    }

    private func intensityColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.secondary.opacity(0.15)
        case 1: return Color.goldPrimary.opacity(0.4)
        case 2: return Color.goldPrimary.opacity(0.6)
        case 3: return Color.goldPrimary.opacity(0.8)
        default: return Color.goldPrimary
        }
    }
}

private struct DayItem: Identifiable {
    let id = UUID()
    let date: Date?
    let day: Int
}
