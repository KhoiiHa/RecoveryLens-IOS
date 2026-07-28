import Foundation

struct WorkoutSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let startDate: Date
    let durationMinutes: Int
    let activityName: String
    let activeEnergyKilocalories: Double?
}
