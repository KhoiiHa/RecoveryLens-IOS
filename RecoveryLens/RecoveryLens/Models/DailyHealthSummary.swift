import Foundation

struct DailyHealthSummary: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let steps: Int?
    let activeEnergyKilocalories: Double?
    let sleepMinutes: Int?
    let workouts: [WorkoutSummary]
}
