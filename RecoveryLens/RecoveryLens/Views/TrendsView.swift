import Charts
import SwiftUI

struct TrendsView: View {
    @Bindable var viewModel: TrendsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .healthKitUnavailable:
                unavailableView(
                    title: "Apple Health nicht verfügbar",
                    systemImage: "heart.slash",
                    message: "Auf diesem Gerät können keine Trends geladen werden."
                )
            case .authorizationRequired:
                unavailableView(
                    title: "Health-Freigabe erforderlich",
                    systemImage: "heart.text.clipboard",
                    message: "Erteile die freiwillige Freigabe zuerst in der Übersicht."
                )
            case .authorizationUnknown:
                unavailableView(
                    title: "Status nicht bestimmbar",
                    systemImage: "questionmark.circle",
                    message: "Der Apple-Health-Status konnte nicht eindeutig bestimmt werden."
                )
            case .empty:
                unavailableView(
                    title: "Keine Trenddaten",
                    systemImage: "chart.xyaxis.line",
                    message: "Für die letzten 30 Tage sind keine lesbaren Werte vorhanden."
                )
            case let .healthOnly(content, message):
                TrendContentView(
                    content: content,
                    checkInNotice: message
                )
            case let .loaded(content):
                TrendContentView(content: content)
            case let .failed(error):
                unavailableView(
                    title: "Trends konnten nicht geladen werden",
                    systemImage: "exclamationmark.triangle",
                    message: error.errorDescription
                        ?? "Beim Laden ist ein unbekannter Fehler aufgetreten."
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("30-Tage-Reflexion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("30-Tage-Daten aktualisieren")
                .disabled(isLoading)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("30-Tage-Daten werden geladen")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func unavailableView(
        title: String,
        systemImage: String,
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct TrendContentView: View {
    let content: TrendContent
    var checkInNotice: String?

    @State private var selectedMetric = WeekMetric.sleep
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                intro
                metricPicker

                if let checkInNotice {
                    notice(message: checkInNotice)
                }

                trendSection
                comparisonSection
                medicalNotice
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Letzte 30 Tage")
                .font(.title2.bold())
            Text("Wähle eine Kennzahl und betrachte vorhandene Werte ohne Ziel- oder Gesundheitsbewertung.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metricPicker: some View {
        Picker("Metrik", selection: $selectedMetric) {
            ForEach(WeekMetric.allCases) { metric in
                Text(metric.pickerTitle).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Verlauf")
                    .font(.title2.bold())
                Spacer()
                Text(selectedMetric.unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if trendPoints.isEmpty {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "chart.bar.xaxis",
                    description: Text(
                        "Für diese Kennzahl liegen im Zeitraum keine Werte vor."
                    )
                )
                .frame(height: 240)
            } else if dynamicTypeSize.isAccessibilitySize {
                accessibleTrendList
            } else {
                Chart {
                    ForEach(trendPoints) { point in
                        BarMark(
                            x: .value("Tag", point.date, unit: .day),
                            y: .value(selectedMetric.unit, point.value)
                        )
                        .foregroundStyle(metricTint)
                        .cornerRadius(2)
                        .accessibilityLabel(formattedDate(point.date))
                        .accessibilityValue(formattedMetricValue(point.value))
                    }

                    if let median {
                        RuleMark(y: .value("Median", median))
                            .foregroundStyle(.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Median")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: trendAxisDates) {
                        AxisTick()
                        AxisValueLabel(
                            format: .dateTime
                                .day()
                                .month(.abbreviated)
                                .locale(Locale(identifier: "de_DE"))
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 240)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(
                    "\(trendPoints.count) von \(content.days.count) Tagen",
                    systemImage: "calendar"
                )
                .accessibilityIdentifier("trend-data-coverage")
                if let median {
                    Text("Median: \(formattedShortValue(median))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mit Energieempfinden")
                .font(.title2.bold())

            Text("Jeder Punkt verbindet eine vorhandene Tageskennzahl mit dem manuellen Energieempfinden desselben Tages.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if content.hasSufficientComparisonData(for: selectedMetric) {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibleComparisonList
                } else {
                    Chart(comparisonPoints) { point in
                        PointMark(
                            x: .value(selectedMetric.unit, point.metricValue),
                            y: .value("Energieempfinden", point.energyLevel)
                        )
                        .foregroundStyle(metricTint)
                        .symbolSize(58)
                        .accessibilityLabel(formattedDate(point.date))
                        .accessibilityValue(
                            "\(formattedMetricValue(point.metricValue)), Energieempfinden \(point.energyLevel) von 5"
                        )
                    }
                    .chartYScale(domain: 1...5)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 2, 3, 4, 5])
                    }
                    .frame(height: 220)
                }
            } else {
                ContentUnavailableView(
                    "Noch zu wenige Vergleichstage",
                    systemImage: "circle.grid.cross",
                    description: Text(
                        "Mindestens fünf Tage mit beiden Werten sind nötig. Aktuell: \(comparisonPoints.count)."
                    )
                )
                .frame(minHeight: 190)
            }

            Text("Die Darstellung zeigt nur zeitgleiche Beobachtungen. Sie belegt keine Ursache oder Wirkung.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var accessibleTrendList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(trendPoints) { point in
                HStack {
                    Text(formattedDate(point.date))
                    Spacer()
                    Text(formattedShortValue(point.value))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                Divider()
            }
        }
    }

    private var accessibleComparisonList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(comparisonPoints) { point in
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate(point.date))
                        .font(.headline)
                    Text(formattedMetricValue(point.metricValue))
                    Text("Energieempfinden: \(point.energyLevel) von 5")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                Divider()
            }
        }
    }

    private func notice(message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var medicalNotice: some View {
        Label(
            "Keine medizinische Bewertung oder konkrete Gesundheitsempfehlung.",
            systemImage: "info.circle"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var trendPoints: [TrendChartPoint] {
        content.points(for: selectedMetric)
    }

    private var comparisonPoints: [EnergyComparisonPoint] {
        content.comparisonPoints(for: selectedMetric)
    }

    private var trendAxisDates: [Date] {
        stride(from: 0, to: content.days.count, by: 7)
            .prefix(4)
            .map { content.days[$0].date }
    }

    private var median: Double? {
        content.median(for: selectedMetric)
    }

    private var metricTint: Color {
        switch selectedMetric {
        case .steps:
            .blue
        case .activeEnergy:
            .orange
        case .sleep:
            .indigo
        }
    }

    private func formattedMetricValue(_ value: Double) -> String {
        switch selectedMetric {
        case .steps:
            "\(Int(value.rounded()).formatted()) Schritte"
        case .activeEnergy:
            "\(Int(value.rounded()).formatted()) Kilokalorien"
        case .sleep:
            formattedShortValue(value) + " Stunden"
        }
    }

    private func formattedShortValue(_ value: Double) -> String {
        switch selectedMetric {
        case .steps, .activeEnergy:
            Int(value.rounded()).formatted()
        case .sleep:
            value.formatted(
                .number.precision(.fractionLength(1))
                    .locale(Locale(identifier: "de_DE"))
            )
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(Locale(identifier: "de_DE"))
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TrendsView(
            viewModel: TrendsViewModel(
                healthKitClient: MockHealthKitClient(
                    snapshotResult: .success(DemoData.snapshot)
                ),
                checkInService: PreviewCheckInService(),
                calendar: DemoData.calendar,
                now: { DemoData.referenceDate }
            )
        )
    }
}
#endif
