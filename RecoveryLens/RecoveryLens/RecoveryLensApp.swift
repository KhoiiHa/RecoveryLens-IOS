import Foundation
import SwiftUI

@main
struct RecoveryLensApp: App {
    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-authorizationRequired") {
            ContentView(
                healthKitClient: MockHealthKitClient(
                    authorizationStateResult: .success(.shouldRequest)
                )
            )
        } else if ProcessInfo.processInfo.arguments.contains("-demoData") {
            ContentView(
                healthKitClient: MockHealthKitClient(
                    snapshotResult: .success(DemoData.snapshot)
                ),
                calendar: DemoData.calendar,
                now: { DemoData.referenceDate }
            )
        } else {
            ContentView(healthKitClient: LiveHealthKitClient())
        }
#else
        ContentView(healthKitClient: LiveHealthKitClient())
#endif
    }
}
