import Foundation
import SwiftData
import SwiftUI

@main
struct RecoveryLensApp: App {
    private let modelContainer: ModelContainer?
    private let checkInService: any CheckInService

    init() {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-persistenceUnavailable") {
            modelContainer = nil
            checkInService = UnavailableCheckInService()
            return
        }
#endif

        do {
#if DEBUG
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly:
                    arguments.contains("-portfolioScreenshots")
                    || arguments.contains("-accessibilityText")
            )
            let container = try ModelContainer(
                for: DailyCheckIn.self,
                configurations: configuration
            )
#else
            let container = try ModelContainer(for: DailyCheckIn.self)
#endif
            modelContainer = container
            checkInService = SwiftDataCheckInService(
                modelContext: container.mainContext
            )
        } catch {
            modelContainer = nil
            checkInService = UnavailableCheckInService()
        }
    }

    var body: some Scene {
        WindowGroup {
            configuredRootView
        }
    }

    @ViewBuilder
    private var configuredRootView: some View {
        if let modelContainer {
            rootView
                .modelContainer(modelContainer)
        } else {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
#if DEBUG
        if let scenario = DebugHealthScenario(
            arguments: ProcessInfo.processInfo.arguments
        ) {
            debugContent(for: scenario)
        } else {
            ContentView(
                healthKitClient: LiveHealthKitClient(),
                checkInService: checkInService
            )
        }
#else
        ContentView(
            healthKitClient: LiveHealthKitClient(),
            checkInService: checkInService
        )
#endif
    }

#if DEBUG
    @ViewBuilder
    private func debugContent(for scenario: DebugHealthScenario) -> some View {
        if scenario.usesAccessibilityTextSize {
            debugRootView(for: scenario)
                .environment(\.dynamicTypeSize, .accessibility5)
        } else {
            debugRootView(for: scenario)
        }
    }

    private func debugRootView(
        for scenario: DebugHealthScenario
    ) -> ContentView {
        ContentView(
            healthKitClient: scenario.healthKitClient,
            checkInService: checkInService,
            calendar: DemoData.calendar,
            now: { DemoData.referenceDate }
        )
    }
#endif
}

#if DEBUG
private enum DebugHealthScenario {
    case authorizationRequired
    case healthKitUnavailable
    case authorizationUnknown
    case loading
    case emptyData
    case partialData
    case queryError
    case demoData
    case portfolioScreenshots
    case accessibilityText

    init?(arguments: [String]) {
        let scenarios: [(argument: String, scenario: Self)] = [
            ("-authorizationRequired", .authorizationRequired),
            ("-healthKitUnavailable", .healthKitUnavailable),
            ("-authorizationUnknown", .authorizationUnknown),
            ("-loading", .loading),
            ("-emptyData", .emptyData),
            ("-partialData", .partialData),
            ("-queryError", .queryError),
            ("-demoData", .demoData),
            ("-portfolioScreenshots", .portfolioScreenshots),
            ("-accessibilityText", .accessibilityText),
        ]

        guard let scenario = scenarios.first(
            where: { arguments.contains($0.argument) }
        ) else {
            return nil
        }

        self = scenario.scenario
    }

    var healthKitClient: any HealthKitClient {
        switch self {
        case .authorizationRequired:
            MockHealthKitClient(
                authorizationStateResult: .success(.shouldRequest)
            )
        case .healthKitUnavailable:
            MockHealthKitClient(
                authorizationStateResult: .success(.unavailable)
            )
        case .authorizationUnknown:
            MockHealthKitClient(
                authorizationStateResult: .success(.unknown)
            )
        case .loading:
            DebugLoadingHealthKitClient()
        case .emptyData:
            MockHealthKitClient(snapshotResult: .success(.empty))
        case .partialData:
            MockHealthKitClient(
                snapshotResult: .success(DemoData.partialSnapshot)
            )
        case .queryError:
            MockHealthKitClient(snapshotResult: .failure(.queryFailed))
        case .demoData, .portfolioScreenshots, .accessibilityText:
            MockHealthKitClient(
                snapshotResult: .success(DemoData.snapshot)
            )
        }
    }

    var usesAccessibilityTextSize: Bool {
        self == .accessibilityText
    }
}

private struct DebugLoadingHealthKitClient: HealthKitClient {
    func authorizationState() async throws -> HealthKitAuthorizationState {
        try await Task.sleep(nanoseconds: 60_000_000_000)
        return .requestNotNeeded
    }

    func requestAuthorization() async throws {}

    func fetchSnapshot(
        from startDate: Date,
        to endDate: Date
    ) async throws -> HealthDataSnapshot {
        .empty
    }
}
#endif
