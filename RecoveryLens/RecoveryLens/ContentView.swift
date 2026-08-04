import Foundation
import SwiftUI

struct ContentView: View {
    @State private var dashboardViewModel: DashboardViewModel
    @State private var checkInViewModel: CheckInViewModel
    @State private var trendsViewModel: TrendsViewModel
    @Environment(\.scenePhase) private var scenePhase

    private let now: () -> Date

    init(
        healthKitClient: any HealthKitClient,
        checkInService: any CheckInService,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.now = now
        _dashboardViewModel = State(
            initialValue: DashboardViewModel(
                healthKitClient: healthKitClient,
                calendar: calendar,
                now: now
            )
        )
        _checkInViewModel = State(
            initialValue: CheckInViewModel(
                checkInService: checkInService,
                date: now(),
                calendar: calendar
            )
        )
        _trendsViewModel = State(
            initialValue: TrendsViewModel(
                healthKitClient: healthKitClient,
                checkInService: checkInService,
                calendar: calendar,
                now: now
            )
        )
    }

    var body: some View {
        TabView {
            NavigationStack {
                dashboardContent
            }
            .tabItem {
                Label("Übersicht", systemImage: "chart.bar.fill")
            }
            .task {
                guard case .idle = dashboardViewModel.state else {
                    return
                }

                await dashboardViewModel.load()
            }

            NavigationStack {
                CheckInView(viewModel: checkInViewModel)
            }
            .tabItem {
                Label("Check-in", systemImage: "checkmark.circle.fill")
            }

            NavigationStack {
                InfoView()
            }
            .tabItem {
                Label("Info", systemImage: "info.circle.fill")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            checkInViewModel.refreshDateIfNeeded(now())
            Task {
                await dashboardViewModel.refresh()
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: .NSCalendarDayChanged
            ) {
                guard !Task.isCancelled else {
                    return
                }

                checkInViewModel.refreshDateIfNeeded(now())
                await dashboardViewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        switch dashboardViewModel.state {
        case .idle, .loading:
            loadingView
        case .healthKitUnavailable:
            statusView(
                title: "Apple Health nicht verfügbar",
                systemImage: "heart.slash",
                message: "Auf diesem Gerät können keine Health-Daten gelesen werden.",
                actionTitle: "Erneut prüfen"
            )
        case .authorizationRequired:
            HealthAuthorizationView {
                await dashboardViewModel.requestAuthorization()
            }
        case .authorizationUnknown:
            statusView(
                title: "Status nicht bestimmbar",
                systemImage: "questionmark.circle",
                message: "Der Apple-Health-Berechtigungsstatus konnte nicht eindeutig bestimmt werden.",
                actionTitle: "Erneut prüfen"
            )
        case .empty:
            statusView(
                title: "Keine Health-Daten",
                systemImage: "chart.bar.xaxis",
                message: "Für die letzten sieben Tage sind keine lesbaren Daten vorhanden.",
                actionTitle: "Aktualisieren"
            )
        case let .partial(content):
            DashboardView(
                content: content,
                trendsViewModel: trendsViewModel,
                showsMissingDataNotice: true,
                isRefreshing: dashboardViewModel.isRefreshing,
                onRefresh: dashboardViewModel.refresh
            )
        case let .loaded(content):
            DashboardView(
                content: content,
                trendsViewModel: trendsViewModel,
                showsMissingDataNotice: false,
                isRefreshing: dashboardViewModel.isRefreshing,
                onRefresh: dashboardViewModel.refresh
            )
        case let .failed(error):
            statusView(
                title: "Daten konnten nicht geladen werden",
                systemImage: "exclamationmark.triangle",
                message: error.errorDescription
                    ?? "Beim Laden ist ein unbekannter Fehler aufgetreten.",
                actionTitle: "Erneut versuchen"
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Health-Daten werden geladen")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func statusView(
        title: String,
        systemImage: String,
        message: String,
        actionTitle: String
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle) {
                Task {
                    await dashboardViewModel.load()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#if DEBUG
#Preview("Berechtigung") {
    ContentView(
        healthKitClient: MockHealthKitClient(
            authorizationStateResult: .success(.shouldRequest)
        ),
        checkInService: PreviewCheckInService()
    )
}

#Preview("Dashboard") {
    ContentView(
        healthKitClient: MockHealthKitClient(
            snapshotResult: .success(DemoData.snapshot)
        ),
        checkInService: PreviewCheckInService()
    )
}
#endif
