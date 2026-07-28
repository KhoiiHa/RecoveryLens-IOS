import Foundation
import SwiftData
import SwiftUI

@main
struct RecoveryLensApp: App {
    private let modelContainer: ModelContainer
    private let checkInService: SwiftDataCheckInService

    init() {
        do {
            let container = try ModelContainer(for: DailyCheckIn.self)
            modelContainer = container
            checkInService = SwiftDataCheckInService(
                modelContext: container.mainContext
            )
        } catch {
            fatalError("SwiftData konnte nicht initialisiert werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder
    private var rootView: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-authorizationRequired") {
            ContentView(
                healthKitClient: MockHealthKitClient(
                    authorizationStateResult: .success(.shouldRequest)
                ),
                checkInService: checkInService
            )
        } else if ProcessInfo.processInfo.arguments.contains("-demoData") {
            ContentView(
                healthKitClient: MockHealthKitClient(
                    snapshotResult: .success(DemoData.snapshot)
                ),
                checkInService: checkInService,
                calendar: DemoData.calendar,
                now: { DemoData.referenceDate }
            )
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
}
