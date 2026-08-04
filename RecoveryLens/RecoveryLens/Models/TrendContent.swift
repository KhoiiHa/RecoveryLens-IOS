import Foundation

nonisolated struct TrendChartPoint: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let value: Double
}

nonisolated struct EnergyComparisonPoint: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let metricValue: Double
    let energyLevel: Int
}

nonisolated struct TrendContent: Sendable {
    static let minimumComparisonCount = 5

    let days: [DailyHealthSummary]
    let checkIns: [DailyCheckInSummary]

    private let calendar: Calendar

    init(
        days: [DailyHealthSummary],
        checkIns: [DailyCheckInSummary],
        calendar: Calendar = .current
    ) {
        self.days = days.sorted { $0.date < $1.date }
        self.checkIns = checkIns.sorted { $0.date < $1.date }
        self.calendar = calendar
    }

    var hasAnyHealthData: Bool {
        days.contains { day in
            WeekMetric.allCases.contains { metric in
                value(for: metric, in: day) != nil
            }
        }
    }

    func points(for metric: WeekMetric) -> [TrendChartPoint] {
        days.compactMap { day in
            guard let value = value(for: metric, in: day) else {
                return nil
            }

            return TrendChartPoint(date: day.date, value: value)
        }
    }

    func median(for metric: WeekMetric) -> Double? {
        let values = points(for: metric).map(\.value).sorted()
        guard !values.isEmpty else {
            return nil
        }

        let middleIndex = values.count / 2
        if values.count.isMultiple(of: 2) {
            return (values[middleIndex - 1] + values[middleIndex]) / 2
        }

        return values[middleIndex]
    }

    func comparisonPoints(
        for metric: WeekMetric
    ) -> [EnergyComparisonPoint] {
        days.compactMap { day in
            guard let metricValue = value(for: metric, in: day),
                  let checkIn = checkIns.first(where: {
                      calendar.isDate($0.date, inSameDayAs: day.date)
                  }) else {
                return nil
            }

            return EnergyComparisonPoint(
                date: day.date,
                metricValue: metricValue,
                energyLevel: checkIn.energyLevel
            )
        }
    }

    func hasSufficientComparisonData(for metric: WeekMetric) -> Bool {
        comparisonPoints(for: metric).count >= Self.minimumComparisonCount
    }

    private func value(
        for metric: WeekMetric,
        in day: DailyHealthSummary
    ) -> Double? {
        switch metric {
        case .steps:
            day.steps.map(Double.init)
        case .activeEnergy:
            day.activeEnergyKilocalories
        case .sleep:
            day.sleepMinutes.map { Double($0) / 60 }
        }
    }
}
