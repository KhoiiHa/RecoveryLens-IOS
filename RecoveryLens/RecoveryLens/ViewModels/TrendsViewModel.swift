import Foundation
import Observation

@MainActor
@Observable
final class TrendsViewModel {
    enum State {
        case idle
        case loading
        case healthKitUnavailable
        case authorizationRequired
        case authorizationUnknown
        case empty
        case healthOnly(TrendContent, String)
        case loaded(TrendContent)
        case failed(HealthKitClientError)
    }

    private(set) var state: State = .idle

    private let healthKitClient: any HealthKitClient
    private let checkInService: any CheckInService
    private let aggregator: HealthSummaryAggregator
    private let calendar: Calendar
    private let now: () -> Date
    private var isLoading = false

    init(
        healthKitClient: any HealthKitClient,
        checkInService: any CheckInService,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.healthKitClient = healthKitClient
        self.checkInService = checkInService
        self.aggregator = HealthSummaryAggregator(calendar: calendar)
        self.calendar = calendar
        self.now = now
    }

    func load() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        state = .loading
        defer { isLoading = false }

        let authorizationState: HealthKitAuthorizationState
        do {
            authorizationState = try await healthKitClient.authorizationState()
        } catch is CancellationError {
            state = .idle
            return
        } catch {
            state = .failed(
                clientError(
                    from: error,
                    fallback: .authorizationStatusUnavailable
                )
            )
            return
        }

        switch authorizationState {
        case .unavailable:
            state = .healthKitUnavailable
        case .shouldRequest:
            state = .authorizationRequired
        case .unknown:
            state = .authorizationUnknown
        case .requestNotNeeded:
            await loadTrendData()
        }
    }

    private func loadTrendData() async {
        let referenceDate = now()
        let todayStart = calendar.startOfDay(for: referenceDate)

        guard let firstDisplayedDay = calendar.date(
            byAdding: .day,
            value: -29,
            to: todayStart
        ), let previousDay = calendar.date(
            byAdding: .day,
            value: -1,
            to: firstDisplayedDay
        ), let healthStart = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: previousDay
        ), let rangeEnd = calendar.date(
            byAdding: .day,
            value: 1,
            to: todayStart
        ) else {
            state = .failed(.invalidDateRange)
            return
        }

        let snapshot: HealthDataSnapshot
        do {
            snapshot = try await healthKitClient.fetchSnapshot(
                from: healthStart,
                to: rangeEnd,
                scope: .trends
            )
        } catch is CancellationError {
            state = .idle
            return
        } catch {
            state = .failed(clientError(from: error, fallback: .queryFailed))
            return
        }

        let days = aggregator.summaries(
            from: snapshot,
            endingAt: referenceDate,
            dayCount: 30
        )
        let healthContent = TrendContent(
            days: days,
            checkIns: [],
            calendar: calendar
        )

        guard healthContent.hasAnyHealthData else {
            state = .empty
            return
        }

        do {
            let checkIns = try checkInService.checkInSummaries(
                from: firstDisplayedDay,
                to: rangeEnd
            )
            state = .loaded(
                TrendContent(
                    days: days,
                    checkIns: checkIns,
                    calendar: calendar
                )
            )
        } catch {
            let message = error.localizedDescription.isEmpty
                ? "Lokale Check-ins konnten nicht geladen werden."
                : error.localizedDescription
            state = .healthOnly(healthContent, message)
        }
    }

    private func clientError(
        from error: Error,
        fallback: HealthKitClientError
    ) -> HealthKitClientError {
        error as? HealthKitClientError ?? fallback
    }
}
