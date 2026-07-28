import Charts
import SwiftUI

struct WeekOverviewView: View {
    let content: WeekOverviewContent

    @State private var selectedMetric = WeekMetric.steps

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
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedMetric.title)
                    .font(.title2.bold())
                Spacer()
                Text(selectedMetric.unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if chartPoints.isEmpty {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "chart.bar.xaxis",
                    description: Text(
                        "Für diese Metrik liegen im Zeitraum keine Werte vor."
                    )
                )
                .frame(height: 220)
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
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.headline)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.activityName)
                    .font(.headline)

                Text(formattedStartDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.durationMinutes) Min.")
                    .font(.subheadline.weight(.medium))

                if let energy = workout.activeEnergyKilocalories {
                    Text("\(Int(energy.rounded()).formatted()) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
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
