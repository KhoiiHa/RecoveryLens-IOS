import Foundation
import HealthKit

struct LiveHealthKitClient: HealthKitClient {
    private let healthStore: HKHealthStore
    private let calendar: Calendar
    private let isHealthDataAvailable: @Sendable () -> Bool

    private static let stepType = HKQuantityType(.stepCount)
    private static let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private static let sleepType = HKCategoryType(.sleepAnalysis)
    private static let workoutType = HKWorkoutType.workoutType()

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        calendar: Calendar = .current,
        isHealthDataAvailable: @escaping @Sendable () -> Bool = {
            HKHealthStore.isHealthDataAvailable()
        }
    ) {
        self.healthStore = healthStore
        self.calendar = calendar
        self.isHealthDataAvailable = isHealthDataAvailable
    }

    func authorizationState() async throws -> HealthKitAuthorizationState {
        guard isHealthDataAvailable() else {
            return .unavailable
        }

        do {
            let status = try await authorizationRequestStatus()
            return Self.authorizationState(from: status)
        } catch {
            throw HealthKitClientError.authorizationStatusUnavailable
        }
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: readTypes
            )
        } catch {
            throw HealthKitClientError.authorizationRequestFailed
        }
    }

    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date,
        scope: HealthDataQueryScope
    ) async throws -> HealthDataSnapshot {
        guard isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }
        guard startDate < endDate else {
            throw HealthKitClientError.invalidDateRange
        }

        do {
            async let stepSamples = dailyQuantitySamples(
                for: Self.stepType,
                unit: .count(),
                from: startDate,
                to: endDate
            )
            async let activeEnergySamples = dailyQuantitySamples(
                for: Self.activeEnergyType,
                unit: .kilocalorie(),
                from: startDate,
                to: endDate
            )
            async let sleepSamples = sleepSamples(
                from: startDate,
                to: endDate
            )
            async let workouts = workouts(
                from: startDate,
                to: endDate,
                scope: scope
            )

            return try await HealthDataSnapshot(
                stepSamples: stepSamples,
                activeEnergySamples: activeEnergySamples,
                sleepSamples: sleepSamples,
                workouts: workouts
            )
        } catch let error as HealthKitClientError {
            throw error
        } catch {
            throw HealthKitClientError.queryFailed
        }
    }

    static func authorizationState(
        from status: HKAuthorizationRequestStatus
    ) -> HealthKitAuthorizationState {
        switch status {
        case .shouldRequest:
            .shouldRequest
        case .unnecessary:
            .requestNotNeeded
        case .unknown:
            .unknown
        @unknown default:
            .unknown
        }
    }

    static func activityName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:
            "Laufen"
        case .cycling:
            "Radfahren"
        case .walking:
            "Gehen"
        case .hiking:
            "Wandern"
        case .traditionalStrengthTraining:
            "Krafttraining"
        case .functionalStrengthTraining:
            "Funktionelles Krafttraining"
        case .yoga:
            "Yoga"
        case .swimming:
            "Schwimmen"
        case .highIntensityIntervalTraining:
            "HIIT"
        default:
            "Training"
        }
    }

    private var readTypes: Set<HKObjectType> {
        [
            Self.stepType,
            Self.activeEnergyType,
            Self.sleepType,
            Self.workoutType,
        ]
    }

    private func authorizationRequestStatus() async throws
        -> HKAuthorizationRequestStatus {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.getRequestStatusForAuthorization(
                toShare: [],
                read: readTypes
            ) { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    private func dailyQuantitySamples(
        for type: HKQuantityType,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [QuantitySample] {
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )
        let predicate = HKSamplePredicate.quantitySample(
            type: type,
            predicate: datePredicate
        )
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: DateComponents(day: 1)
        )
        let collection = try await descriptor.result(for: healthStore)
        var samples: [QuantitySample] = []

        collection.enumerateStatistics(
            from: startDate,
            to: endDate
        ) { statistics, _ in
            guard let quantity = statistics.sumQuantity() else {
                return
            }

            samples.append(
                QuantitySample(
                    date: statistics.startDate,
                    value: quantity.doubleValue(for: unit)
                )
            )
        }

        return samples
    }

    private func sleepSamples(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [SleepSample] {
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let predicate = HKSamplePredicate.categorySample(
            type: Self.sleepType,
            predicate: datePredicate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [predicate],
            sortDescriptors: [SortDescriptor(\.startDate)],
            limit: nil
        )
        let samples = try await descriptor.result(for: healthStore)

        return samples.compactMap { sample in
            guard let state = Self.sleepState(for: sample.value) else {
                return nil
            }

            return SleepSample(
                startDate: sample.startDate,
                endDate: sample.endDate,
                state: state,
                sourceIdentifier: sample.sourceRevision.source.bundleIdentifier
            )
        }
    }

    static func sleepState(for rawValue: Int) -> SleepState? {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: rawValue) else {
            return nil
        }

        switch value {
        case .asleepUnspecified:
            return SleepState.asleepUnspecified
        case .asleepCore:
            return SleepState.asleepCore
        case .asleepDeep:
            return SleepState.asleepDeep
        case .asleepREM:
            return SleepState.asleepREM
        case .awake:
            return SleepState.awake
        default:
            return nil
        }
    }

    private func workouts(
        from startDate: Date,
        to endDate: Date,
        scope: HealthDataQueryScope
    ) async throws -> [WorkoutSummary] {
        guard scope.includesWorkouts else {
            return []
        }

        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )
        let predicate = HKSamplePredicate.workout(datePredicate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [predicate],
            sortDescriptors: [SortDescriptor(\.startDate)],
            limit: nil
        )
        let workouts = try await descriptor.result(for: healthStore)

        return workouts.map { workout in
            let energy = workout
                .statistics(for: Self.activeEnergyType)?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie())

            return WorkoutSummary(
                id: workout.uuid,
                startDate: workout.startDate,
                durationMinutes: Int((workout.duration / 60).rounded()),
                activityName: Self.activityName(
                    for: workout.workoutActivityType
                ),
                activeEnergyKilocalories: energy
            )
        }
    }
}
