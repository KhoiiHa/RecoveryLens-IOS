import Foundation

struct DashboardContent {
    let today: DailyHealthSummary
    let week: [DailyHealthSummary]

    var workouts: [WorkoutSummary] {
        week
            .flatMap(\.workouts)
            .sorted { $0.startDate > $1.startDate }
    }

    var hasAnyData: Bool {
        week.contains { summary in
            summary.steps != nil
                || summary.activeEnergyKilocalories != nil
                || summary.sleepMinutes != nil
                || !summary.workouts.isEmpty
        }
    }

    var hasMissingHealthValues: Bool {
        week.contains { summary in
            summary.steps == nil
                || summary.activeEnergyKilocalories == nil
                || summary.sleepMinutes == nil
        }
    }
}
