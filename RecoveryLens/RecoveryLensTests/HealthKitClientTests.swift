import Foundation
import HealthKit
import Testing
@testable import RecoveryLens

@MainActor
struct HealthKitClientTests {
    @Test
    func authorizationRequestStatusesAreMappedWithoutClaimingReadAccess() {
        #expect(
            LiveHealthKitClient.authorizationState(from: .shouldRequest)
                == .shouldRequest
        )
        #expect(
            LiveHealthKitClient.authorizationState(from: .unnecessary)
                == .requestNotNeeded
        )
        #expect(
            LiveHealthKitClient.authorizationState(from: .unknown)
                == .unknown
        )
    }

    @Test
    func unavailableHealthKitIsReportedBeforeAuthorizationOrQueries() async {
        let client = LiveHealthKitClient(
            isHealthDataAvailable: { false }
        )

        do {
            let state = try await client.authorizationState()
            #expect(state == .unavailable)
        } catch {
            Issue.record("Der Verfügbarkeitsstatus darf nicht fehlschlagen.")
        }

        await expectError(.healthDataUnavailable) {
            try await client.requestAuthorization()
        }
        await expectError(.healthDataUnavailable) {
            _ = try await client.fetchSnapshot(
                from: Date(timeIntervalSinceReferenceDate: 0),
                to: Date(timeIntervalSinceReferenceDate: 1)
            )
        }
    }

    @Test
    func invalidDateRangeFailsBeforeRunningQueries() async {
        let client = LiveHealthKitClient(
            isHealthDataAvailable: { true }
        )
        let date = Date(timeIntervalSinceReferenceDate: 100)

        await expectError(.invalidDateRange) {
            _ = try await client.fetchSnapshot(from: date, to: date)
        }
    }

    @Test
    func mockClientReturnsConfiguredStateAndSnapshot() async throws {
        let client = MockHealthKitClient(
            authorizationStateResult: .success(.shouldRequest),
            snapshotResult: .success(DemoData.snapshot)
        )

        let state = try await client.authorizationState()
        try await client.requestAuthorization()
        let snapshot = try await client.fetchSnapshot(
            from: DemoData.referenceDate.addingTimeInterval(-604_800),
            to: DemoData.referenceDate
        )

        #expect(state == .shouldRequest)
        #expect(snapshot.stepSamples.count == DemoData.snapshot.stepSamples.count)
        #expect(
            snapshot.stepSamples.last?.value
                == DemoData.snapshot.stepSamples.last?.value
        )
        #expect(snapshot.workouts.count == DemoData.snapshot.workouts.count)
    }

    @Test
    func mockClientPropagatesConfiguredErrors() async {
        let client = MockHealthKitClient(
            authorizationStateResult: .failure(
                .authorizationStatusUnavailable
            ),
            authorizationRequestResult: .failure(
                .authorizationRequestFailed
            ),
            snapshotResult: .failure(.queryFailed)
        )

        await expectError(.authorizationStatusUnavailable) {
            _ = try await client.authorizationState()
        }
        await expectError(.authorizationRequestFailed) {
            try await client.requestAuthorization()
        }
        await expectError(.queryFailed) {
            _ = try await client.fetchSnapshot(
                from: Date(timeIntervalSinceReferenceDate: 0),
                to: Date(timeIntervalSinceReferenceDate: 1)
            )
        }
    }

    @Test
    func commonWorkoutTypesHaveUnderstandableNames() {
        #expect(
            LiveHealthKitClient.activityName(for: .running) == "Laufen"
        )
        #expect(
            LiveHealthKitClient.activityName(
                for: .traditionalStrengthTraining
            ) == "Krafttraining"
        )
        #expect(
            LiveHealthKitClient.activityName(for: .other) == "Training"
        )
    }

    @Test
    func sleepCategoriesAreMappedWithoutTreatingInBedAsSleep() {
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            ) == .asleepUnspecified
        )
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.asleepCore.rawValue
            ) == .asleepCore
        )
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            ) == .asleepDeep
        )
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ) == .asleepREM
        )
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.awake.rawValue
            ) == .awake
        )
        #expect(
            LiveHealthKitClient.sleepState(
                for: HKCategoryValueSleepAnalysis.inBed.rawValue
            ) == nil
        )
    }

    private func expectError(
        _ expectedError: HealthKitClientError,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("Erwarteter Fehler wurde nicht ausgelöst.")
        } catch let error as HealthKitClientError {
            #expect(error == expectedError)
        } catch {
            Issue.record("Unerwarteter Fehlertyp: \(error)")
        }
    }
}
