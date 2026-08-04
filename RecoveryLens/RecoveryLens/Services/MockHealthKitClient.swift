import Foundation

struct MockHealthKitClient: HealthKitClient {
    let authorizationStateResult: Result<
        HealthKitAuthorizationState,
        HealthKitClientError
    >
    let authorizationRequestResult: Result<Void, HealthKitClientError>
    let snapshotResult: Result<HealthDataSnapshot, HealthKitClientError>

    init(
        authorizationStateResult: Result<
            HealthKitAuthorizationState,
            HealthKitClientError
        > = .success(.requestNotNeeded),
        authorizationRequestResult: Result<
            Void,
            HealthKitClientError
        > = .success(()),
        snapshotResult: Result<
            HealthDataSnapshot,
            HealthKitClientError
        > = .success(.empty)
    ) {
        self.authorizationStateResult = authorizationStateResult
        self.authorizationRequestResult = authorizationRequestResult
        self.snapshotResult = snapshotResult
    }

    func authorizationState() async throws -> HealthKitAuthorizationState {
        try authorizationStateResult.get()
    }

    func requestAuthorization() async throws {
        try authorizationRequestResult.get()
    }

    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date,
        scope: HealthDataQueryScope
    ) async throws -> HealthDataSnapshot {
        let snapshot = try snapshotResult.get()
        guard scope.includesWorkouts else {
            return HealthDataSnapshot(
                stepSamples: snapshot.stepSamples,
                activeEnergySamples: snapshot.activeEnergySamples,
                sleepSamples: snapshot.sleepSamples,
                workouts: []
            )
        }

        return snapshot
    }
}
