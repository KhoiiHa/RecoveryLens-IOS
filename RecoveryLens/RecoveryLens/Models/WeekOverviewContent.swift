import Foundation

nonisolated enum WeekMetric: String, CaseIterable, Identifiable, Sendable {
    case steps
    case activeEnergy
    case sleep

    var id: Self { self }

    var title: String {
        switch self {
        case .steps:
            "Schritte"
        case .activeEnergy:
            "Energie"
        case .sleep:
            "Schlaf"
        }
    }

    var unit: String {
        switch self {
        case .steps:
            "Schritte"
        case .activeEnergy:
            "kcal"
        case .sleep:
            "Stunden"
        }
    }
}

nonisolated struct WeekChartPoint: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let value: Double
}

nonisolated struct WeekOverviewContent: Sendable {
    let days: [DailyHealthSummary]
    let workouts: [WorkoutSummary]

    init(days: [DailyHealthSummary]) {
        self.days = days.sorted { $0.date < $1.date }
        self.workouts = days
            .flatMap(\.workouts)
            .sorted { $0.startDate > $1.startDate }
    }

    func points(for metric: WeekMetric) -> [WeekChartPoint] {
        days.compactMap { day in
            guard let value = value(for: metric, in: day) else {
                return nil
            }

            return WeekChartPoint(date: day.date, value: value)
        }
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
