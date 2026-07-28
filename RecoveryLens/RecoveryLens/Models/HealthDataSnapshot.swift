import Foundation

struct QuantitySample: Equatable, Sendable {
    let date: Date
    let value: Double
}

enum SleepState: Equatable, Sendable {
    case asleep
    case awake
}

struct SleepSample: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let state: SleepState
}

struct HealthDataSnapshot: Equatable, Sendable {
    let stepSamples: [QuantitySample]
    let activeEnergySamples: [QuantitySample]
    let sleepSamples: [SleepSample]
    let workouts: [WorkoutSummary]

    static let empty = HealthDataSnapshot(
        stepSamples: [],
        activeEnergySamples: [],
        sleepSamples: [],
        workouts: []
    )
}
