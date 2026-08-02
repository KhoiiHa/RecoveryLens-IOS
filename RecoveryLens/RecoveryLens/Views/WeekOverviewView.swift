import Charts
import SwiftUI

struct WeekOverviewView: View {
    let content: WeekOverviewContent

    @State private var selectedMetric = WeekMetric.steps
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                metricPicker
                chartSection
                workoutSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Wochenübersicht")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var metricPicker: some View {
        Picker("Metrik", selection: $selectedMetric) {
            ForEach(WeekMetric.allCases) { metric in
                Text(metric.pickerTitle).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricHeader

            if chartPoints.isEmpty {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "chart.bar.xaxis",
                    description: Text(
                        "Für diese Metrik liegen im Zeitraum keine Werte vor."
                    )
                )
                .frame(height: 220)
            } else if dynamicTypeSize.isAccessibilitySize {
                accessibleValueList
            } else {
                Chart(chartPoints) { point in
                    BarMark(
                        x: .value("Tag", point.date, unit: .day),
                        y: .value(selectedMetric.unit, point.value)
                    )
                    .foregroundStyle(chartTint)
                    .cornerRadius(3)
                    .accessibilityLabel(
                        point.date.formatted(
                            .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                                .locale(Locale(identifier: "de_DE"))
                        )
                    )
                    .accessibilityValue(
                        formattedChartValue(point.value)
                    )
                }
                .chartXAxis {
                    AxisMarks(values: content.days.map(\.date)) { _ in
                        AxisTick()
                        AxisValueLabel(
                            format: .dateTime
                                .weekday(.short)
                                .day()
                                .locale(Locale(identifier: "de_DE"))
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
            }

            Text(
                "\(chartPoints.count) von \(content.days.count) Tagen mit Daten"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var metricHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text(selectedMetric.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedMetric.title)
                    .font(.title2.bold())
                Spacer()
                Text(selectedMetric.unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accessibleValueList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(
                Array(chartPoints.enumerated()),
                id: \.element.id
            ) { index, point in
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        point.date.formatted(
                            .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.abbreviated)
                                .locale(Locale(identifier: "de_DE"))
                        )
                    )
                    .font(.headline)

                    Text(formattedChartValue(point.value))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)

                if index < chartPoints.count - 1 {
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trainingseinheiten")
                .font(.title2.bold())

            if content.workouts.isEmpty {
                ContentUnavailableView(
                    "Keine Trainingseinheiten",
                    systemImage: "figure.run",
                    description: Text(
                        "Im Sieben-Tage-Zeitraum wurden keine Workouts gefunden."
                    )
                )
                .frame(minHeight: 180)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(content.workouts.enumerated()),
                        id: \.element.id
                    ) { index, workout in
                        WorkoutRow(workout: workout)

                        if index < content.workouts.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private var chartPoints: [WeekChartPoint] {
        content.points(for: selectedMetric)
    }

    private var chartTint: Color {
        switch selectedMetric {
        case .steps:
            .blue
        case .activeEnergy:
            .orange
        case .sleep:
            .indigo
        }
    }

    private func formattedChartValue(_ value: Double) -> String {
        switch selectedMetric {
        case .steps:
            "\(Int(value.rounded()).formatted()) Schritte"
        case .activeEnergy:
            "\(Int(value.rounded()).formatted()) Kilokalorien"
        case .sleep:
            value.formatted(
                .number.precision(.fractionLength(1))
                    .locale(Locale(identifier: "de_DE"))
            ) + " Stunden"
        }
    }
}

private struct WorkoutRow: View {
    let workout: WorkoutSummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityContent
            } else {
                standardContent
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var standardContent: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                workoutTitle
                workoutDate
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                workoutDuration
                workoutEnergy
            }
        }
    }

    private var accessibilityContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            icon
            workoutTitle
            workoutDate
            workoutDuration
            workoutEnergy
        }
    }

    private var icon: some View {
        Image(systemName: "figure.run")
            .font(.headline)
            .foregroundStyle(.tint)
            .frame(width: 40, height: 40)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    private var workoutTitle: some View {
        Text(workout.activityName)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var workoutDate: some View {
        Text(formattedStartDate)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var workoutDuration: some View {
        Text("\(workout.durationMinutes) Min.")
            .font(.subheadline.weight(.medium))
    }

    @ViewBuilder
    private var workoutEnergy: some View {
        if let energy = workout.activeEnergyKilocalories {
            Text("\(Int(energy.rounded()).formatted()) kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var formattedStartDate: String {
        workout.startDate.formatted(
            .dateTime
                .weekday(.short)
                .day()
                .month(.abbreviated)
                .hour()
                .minute()
                .locale(Locale(identifier: "de_DE"))
        )
    }
}

#Preview {
    NavigationStack {
        WeekOverviewView(
            content: WeekOverviewContent(days: DemoData.summaries)
        )
    }
}
