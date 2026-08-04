import Foundation
import Testing
@testable import RecoveryLens

@MainActor
struct TrendsViewModelTests {
    @Test
    func loadKeepsAuthorizationStatesSeparate() async {
        let requiredClient = TrendsHealthKitSpy(
            authorizationState: .shouldRequest
        )
        let unavailableClient = TrendsHealthKitSpy(
            authorizationState: .unavailable
        )

        let requiredViewModel = makeViewModel(client: requiredClient)
        let unavailableViewModel = makeViewModel(client: unavailableClient)
        await requiredViewModel.load()
        await unavailableViewModel.load()

        guard case .authorizationRequired = requiredViewModel.state else {
            Issue.record("Die ausstehende Freigabe wurde nicht dargestellt.")
            return
        }
        guard case .healthKitUnavailable = unavailableViewModel.state else {
            Issue.record("Nicht verfügbares HealthKit wurde nicht erkannt.")
            return
        }
        #expect(requiredClient.fetchRanges.isEmpty)
        #expect(unavailableClient.fetchRanges.isEmpty)
    }

    @Test
    func loadRequestsThirtyDaysWithSleepContext() async throws {
        let client = TrendsHealthKitSpy(snapshot: DemoData.snapshot)
        let checkInService = TrendsCheckInSpy(
            summaries: [
                DailyCheckInSummary(
                    date: DemoData.referenceDate,
                    energyLevel: 4,
                    moodLevel: 4
                ),
            ]
        )
        let viewModel = makeViewModel(
            client: client,
            checkInService: checkInService
        )

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("Die Trenddaten wurden nicht geladen.")
            return
        }
        let healthRange = try #require(client.fetchRanges.first)
        let checkInRange = try #require(checkInService.fetchRanges.first)
        let expectedHealthStart = try date(dayOffset: -30, hour: 12)
        let expectedFirstDay = try date(dayOffset: -29)
        let expectedEnd = try date(dayOffset: 1)

        #expect(content.days.count == 30)
        #expect(content.points(for: .steps).count == 30)
        #expect(healthRange.start == expectedHealthStart)
        #expect(healthRange.end == expectedEnd)
        #expect(healthRange.scope == .trends)
        #expect(checkInRange.start == expectedFirstDay)
        #expect(checkInRange.end == expectedEnd)
    }

    @Test
    func loadDistinguishesEmptyAndQueryFailure() async {
        let emptyViewModel = makeViewModel(
            client: TrendsHealthKitSpy(snapshot: .empty)
        )
        let failedViewModel = makeViewModel(
            client: TrendsHealthKitSpy(snapshotError: .queryFailed)
        )

        await emptyViewModel.load()
        await failedViewModel.load()

        guard case .empty = emptyViewModel.state else {
            Issue.record("Fehlende Trenddaten wurden nicht als Empty erkannt.")
            return
        }
        guard case let .failed(error) = failedViewModel.state else {
            Issue.record("Der Abfragefehler wurde nicht dargestellt.")
            return
        }
        #expect(error == .queryFailed)
    }

    @Test
    func checkInFailureKeepsHealthTrendsAvailable() async {
        let viewModel = makeViewModel(
            client: TrendsHealthKitSpy(snapshot: DemoData.snapshot),
            checkInService: TrendsCheckInSpy(
                error: CheckInServiceError.persistenceUnavailable
            )
        )

        await viewModel.load()

        guard case let .healthOnly(content, message) = viewModel.state else {
            Issue.record("Health-Trends wurden durch den Check-in-Fehler blockiert.")
            return
        }
        #expect(content.hasAnyHealthData)
        #expect(message == "Lokale Check-ins sind derzeit nicht verfügbar.")
    }

    private func makeViewModel(
        client: TrendsHealthKitSpy,
        checkInService: TrendsCheckInSpy? = nil
    ) -> TrendsViewModel {
        TrendsViewModel(
            healthKitClient: client,
            checkInService: checkInService ?? TrendsCheckInSpy(),
            calendar: DemoData.calendar,
            now: { DemoData.referenceDate }
        )
    }

    private func date(dayOffset: Int, hour: Int = 0) throws -> Date {
        let day = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: DemoData.calendar.startOfDay(for: DemoData.referenceDate)
            )
        )
        return try #require(
            DemoData.calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: day
            )
        )
    }
}

@MainActor
private final class TrendsHealthKitSpy: HealthKitClient {
    struct FetchRange {
        let start: Date
        let end: Date
        let scope: HealthDataQueryScope
    }

    let authorizationStateValue: HealthKitAuthorizationState
    let snapshot: HealthDataSnapshot
    let snapshotError: HealthKitClientError?
    private(set) var fetchRanges: [FetchRange] = []

    init(
        authorizationState: HealthKitAuthorizationState = .requestNotNeeded,
        snapshot: HealthDataSnapshot? = nil,
        snapshotError: HealthKitClientError? = nil
    ) {
        self.authorizationStateValue = authorizationState
        self.snapshot = snapshot ?? .empty
        self.snapshotError = snapshotError
    }

    func authorizationState() async throws -> HealthKitAuthorizationState {
        authorizationStateValue
    }

    func requestAuthorization() async throws {}

    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date,
        scope: HealthDataQueryScope
    ) async throws -> HealthDataSnapshot {
        fetchRanges.append(
            FetchRange(start: startDate, end: endDate, scope: scope)
        )
        if let snapshotError {
            throw snapshotError
        }
        return snapshot
    }
}

@MainActor
private final class TrendsCheckInSpy: CheckInService {
    struct FetchRange {
        let start: Date
        let end: Date
    }

    let summaries: [DailyCheckInSummary]
    let error: CheckInServiceError?
    private(set) var fetchRanges: [FetchRange] = []

    init(
        summaries: [DailyCheckInSummary] = [],
        error: CheckInServiceError? = nil
    ) {
        self.summaries = summaries
        self.error = error
    }

    func checkIn(for date: Date) throws -> DailyCheckIn? {
        nil
    }

    func checkInSummaries(from startDate: Date, to endDate: Date) throws
        -> [DailyCheckInSummary] {
        fetchRanges.append(FetchRange(start: startDate, end: endDate))
        if let error {
            throw error
        }
        return summaries
    }

    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn {
        preconditionFailure("Speichern ist in diesen Tests nicht vorgesehen.")
    }
}
