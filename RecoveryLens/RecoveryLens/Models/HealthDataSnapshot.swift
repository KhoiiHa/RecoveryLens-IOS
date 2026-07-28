import Foundation

struct QuantitySample: Equatable, Sendable {
    let date: Date
    let value: Double
}

enum SleepState: Equatable, Sendable {
    case asleepUnspecified
    case asleepCore
    case asleepDeep
    case asleepREM
    case awake

    var isAsleep: Bool {
        switch self {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            true
        case .awake:
            false
        }
    }
}

struct SleepSample: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let state: SleepState
    let sourceIdentifier: String

    init(
        startDate: Date,
        endDate: Date,
        state: SleepState,
        sourceIdentifier: String = "unknown"
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.state = state
        self.sourceIdentifier = sourceIdentifier
    }
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
