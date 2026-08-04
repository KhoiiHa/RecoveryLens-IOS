import Foundation

nonisolated enum HealthKitAuthorizationState: Equatable, Sendable {
    case unavailable
    case shouldRequest
    case requestNotNeeded
    case unknown
}

nonisolated enum HealthDataQueryScope: Equatable, Sendable {
    case dashboard
    case trends

    var includesWorkouts: Bool {
        self == .dashboard
    }
}

nonisolated enum HealthKitClientError: Error, Equatable, LocalizedError, Sendable {
    case healthDataUnavailable
    case authorizationStatusUnavailable
    case authorizationRequestFailed
    case invalidDateRange
    case queryFailed

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Apple Health ist auf diesem Gerät nicht verfügbar."
        case .authorizationStatusUnavailable:
            "Der Berechtigungsstatus konnte nicht geprüft werden."
        case .authorizationRequestFailed:
            "Die Apple-Health-Berechtigung konnte nicht angefragt werden."
        case .invalidDateRange:
            "Der gewählte Zeitraum ist ungültig."
        case .queryFailed:
            "Die Gesundheitsdaten konnten nicht geladen werden."
        }
    }
}

protocol HealthKitClient: Sendable {
    func authorizationState() async throws -> HealthKitAuthorizationState
    func requestAuthorization() async throws
    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date,
        scope: HealthDataQueryScope
    ) async throws
        -> HealthDataSnapshot
}
