import SwiftUI

struct ContentView: View {
    @State private var viewModel: DashboardViewModel

    init(
        healthKitClient: any HealthKitClient,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        _viewModel = State(
            initialValue: DashboardViewModel(
                healthKitClient: healthKitClient,
                calendar: calendar,
                now: now
            )
        )
    }

    var body: some View {
        NavigationStack {
            content
        }
        .task {
            guard case .idle = viewModel.state else {
                return
            }

            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
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
                await viewModel.requestAuthorization()
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
                showsMissingDataNotice: true,
                onRefresh: viewModel.load
            )
        case let .loaded(content):
            DashboardView(
                content: content,
                showsMissingDataNotice: false,
                onRefresh: viewModel.load
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
                    await viewModel.load()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("Berechtigung") {
    ContentView(
        healthKitClient: MockHealthKitClient(
            authorizationStateResult: .success(.shouldRequest)
        )
    )
}

#Preview("Dashboard") {
    ContentView(
        healthKitClient: MockHealthKitClient(
            snapshotResult: .success(DemoData.snapshot)
        )
    )
}
