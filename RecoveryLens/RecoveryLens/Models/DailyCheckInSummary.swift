import Foundation

nonisolated struct DailyCheckInSummary: Equatable, Sendable {
    let date: Date
    let energyLevel: Int
    let moodLevel: Int
}
