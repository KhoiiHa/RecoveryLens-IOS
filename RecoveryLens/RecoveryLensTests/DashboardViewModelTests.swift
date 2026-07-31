import Foundation
import Testing
@testable import RecoveryLens

@MainActor
struct DashboardViewModelTests {
    @Test
    func loadShowsAuthorizationRequiredBeforeReadingData() async {
        let client = DashboardHealthKitSpy(
            authorizationState: .shouldRequest
        )
        let viewModel = makeViewModel(client: client)

        await viewModel.load()

        guard case .authorizationRequired = viewModel.state else {
            Issue.record("Es wurde keine Autorisierung angefordert.")
            return
        }
        #expect(client.fetchRanges.isEmpty)
    }

    @Test
    func loadDistinguishesUnavailableAndUnknownAuthorization() async {
        let unavailableViewModel = makeViewModel(
            client: DashboardHealthKitSpy(
                authorizationState: .unavailable
            )
        )
        let unknownViewModel = makeViewModel(
            client: DashboardHealthKitSpy(
                authorizationState: .unknown
            )
        )

        await unavailableViewModel.load()
        await unknownViewModel.load()

        guard case .healthKitUnavailable = unavailableViewModel.state else {
            Issue.record("HealthKit wurde nicht als nicht verfügbar erkannt.")
            return
        }
        guard case .authorizationUnknown = unknownViewModel.state else {
            Issue.record("Der unbekannte Status wurde nicht beibehalten.")
            return
        }
    }

    @Test
    func loadCreatesCompleteDashboardContent() async {
        let client = DashboardHealthKitSpy(snapshot: DemoData.snapshot)
        let viewModel = makeViewModel(client: client)

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("Vollständige Demo-Daten wurden nicht geladen.")
            return
        }

        #expect(content.week.count == 7)
        #expect(content.today.steps == 8_840)
        #expect(content.workouts.count == 3)
    }

    @Test
    func loadIncludesSleepContextForSevenLocalCalendarDays() async throws {
        let client = DashboardHealthKitSpy(snapshot: DemoData.snapshot)
        let viewModel = makeViewModel(client: client)

        await viewModel.load()

        let range = try #require(client.fetchRanges.first)
        let expectedStart = try #require(
            DemoData.calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 21,
                    hour: 12
                )
            )
        )
        let expectedEnd = try #require(
            DemoData.calendar.date(
                from: DateComponents(year: 2026, month: 7, day: 29)
            )
        )

        #expect(range.start == expectedStart)
        #expect(range.end == expectedEnd)
    }

    @Test
    func loadDistinguishesEmptyAndPartialData() async {
        let emptyViewModel = makeViewModel(
            client: DashboardHealthKitSpy(snapshot: .empty)
        )
        let partialSnapshot = HealthDataSnapshot(
            stepSamples: [
                QuantitySample(date: DemoData.referenceDate, value: 1_500)
            ],
            activeEnergySamples: [],
            sleepSamples: [],
            workouts: []
        )
        let partialViewModel = makeViewModel(
            client: DashboardHealthKitSpy(snapshot: partialSnapshot)
        )

        await emptyViewModel.load()
        await partialViewModel.load()

        guard case .empty = emptyViewModel.state else {
            Issue.record("Fehlende Daten wurden nicht als Empty erkannt.")
            return
        }
        guard case let .partial(content) = partialViewModel.state else {
            Issue.record("Teilweise Daten wurden nicht separat dargestellt.")
            return
        }
        #expect(content.today.steps == 1_500)
        #expect(content.today.activeEnergyKilocalories == nil)
    }

    @Test
    func authorizationAndQueryErrorsRemainDistinguishable() async {
        let authorizationViewModel = makeViewModel(
            client: DashboardHealthKitSpy(
                authorizationStateError: .authorizationStatusUnavailable
            )
        )
        let queryViewModel = makeViewModel(
            client: DashboardHealthKitSpy(
                snapshotError: .queryFailed
            )
        )

        await authorizationViewModel.load()
        await queryViewModel.load()

        assertFailure(
            authorizationViewModel.state,
            equals: .authorizationStatusUnavailable
        )
        assertFailure(queryViewModel.state, equals: .queryFailed)
    }

    @Test
    func requestAuthorizationLoadsDataAfterSuccessfulRequest() async {
        let client = DashboardHealthKitSpy(snapshot: DemoData.snapshot)
        let viewModel = makeViewModel(client: client)

        await viewModel.requestAuthorization()

        #expect(client.authorizationRequestCount == 1)
        #expect(client.fetchRanges.count == 1)
        guard case .loaded = viewModel.state else {
            Issue.record("Nach der Autorisierung wurden keine Daten geladen.")
            return
        }
    }

    @Test
    func requestAuthorizationKeepsRequestErrorsVisible() async {
        let client = DashboardHealthKitSpy(
            authorizationRequestError: .authorizationRequestFailed
        )
        let viewModel = makeViewModel(client: client)

        await viewModel.requestAuthorization()

        assertFailure(
            viewModel.state,
            equals: .authorizationRequestFailed
        )
        #expect(client.fetchRanges.isEmpty)
    }

    private func makeViewModel(
        client: DashboardHealthKitSpy
    ) -> DashboardViewModel {
        DashboardViewModel(
            healthKitClient: client,
            calendar: DemoData.calendar,
            now: { DemoData.referenceDate }
        )
    }

    private func assertFailure(
        _ state: DashboardViewModel.State,
        equals expectedError: HealthKitClientError
    ) {
        guard case let .failed(error) = state else {
            Issue.record("Der erwartete Fehlerzustand fehlt.")
            return
        }

        #expect(error == expectedError)
    }
}

@MainActor
private final class DashboardHealthKitSpy: HealthKitClient {
    struct FetchRange {
        let start: Date
        let end: Date
    }

    let authorizationStateValue: HealthKitAuthorizationState
    let authorizationStateError: HealthKitClientError?
    let authorizationRequestError: HealthKitClientError?
    let snapshot: HealthDataSnapshot
    let snapshotError: HealthKitClientError?

    private(set) var authorizationRequestCount = 0
    private(set) var fetchRanges: [FetchRange] = []

    init(
        authorizationState: HealthKitAuthorizationState = .requestNotNeeded,
        authorizationStateError: HealthKitClientError? = nil,
        authorizationRequestError: HealthKitClientError? = nil,
        snapshot: HealthDataSnapshot? = nil,
        snapshotError: HealthKitClientError? = nil
    ) {
        self.authorizationStateValue = authorizationState
        self.authorizationStateError = authorizationStateError
        self.authorizationRequestError = authorizationRequestError
        self.snapshot = snapshot ?? .empty
        self.snapshotError = snapshotError
    }

    func authorizationState() async throws -> HealthKitAuthorizationState {
        if let authorizationStateError {
            throw authorizationStateError
        }

        return authorizationStateValue
    }

    func requestAuthorization() async throws {
        authorizationRequestCount += 1

        if let authorizationRequestError {
            throw authorizationRequestError
        }
    }

    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date
    ) async throws -> HealthDataSnapshot {
        fetchRanges.append(FetchRange(start: startDate, end: endDate))

        if let snapshotError {
            throw snapshotError
        }

        return snapshot
    }
}
