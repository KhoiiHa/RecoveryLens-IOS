import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    enum State {
        case idle
        case loading
        case healthKitUnavailable
        case authorizationRequired
        case authorizationUnknown
        case empty
        case partial(DashboardContent)
        case loaded(DashboardContent)
        case failed(HealthKitClientError)
    }

    private(set) var state: State = .idle

    private let healthKitClient: any HealthKitClient
    private let aggregator: HealthSummaryAggregator
    private let calendar: Calendar
    private let now: () -> Date

    init(
        healthKitClient: any HealthKitClient,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.healthKitClient = healthKitClient
        self.aggregator = HealthSummaryAggregator(calendar: calendar)
        self.calendar = calendar
        self.now = now
    }

    func load() async {
        state = .loading

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
            await loadHealthData()
        }
    }

    func requestAuthorization() async {
        state = .loading

        do {
            try await healthKitClient.requestAuthorization()
        } catch is CancellationError {
            state = .idle
            return
        } catch {
            state = .failed(
                clientError(
                    from: error,
                    fallback: .authorizationRequestFailed
                )
            )
            return
        }

        await loadHealthData()
    }

    private func loadHealthData() async {
        let referenceDate = now()
        let todayStart = calendar.startOfDay(for: referenceDate)

        guard let startDate = calendar.date(
            byAdding: .day,
            value: -6,
            to: todayStart
        ), let endDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: todayStart
        ) else {
            state = .failed(.invalidDateRange)
            return
        }

        do {
            let snapshot = try await healthKitClient.fetchSnapshot(
                from: startDate,
                to: endDate
            )
            let summaries = aggregator.summaries(
                from: snapshot,
                endingAt: referenceDate
            )

            guard let today = summaries.last else {
                state = .empty
                return
            }

            let content = DashboardContent(today: today, week: summaries)

            if !content.hasAnyData {
                state = .empty
            } else if content.hasMissingHealthValues {
                state = .partial(content)
            } else {
                state = .loaded(content)
            }
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(
                clientError(from: error, fallback: .queryFailed)
            )
        }
    }

    private func clientError(
        from error: Error,
        fallback: HealthKitClientError
    ) -> HealthKitClientError {
        error as? HealthKitClientError ?? fallback
    }
}
