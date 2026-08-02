import SwiftUI

struct DashboardView: View {
    let content: DashboardContent
    let showsMissingDataNotice: Bool
    let isRefreshing: Bool
    let onRefresh: () async -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                dateHeader

                if showsMissingDataNotice {
                    missingDataNotice
                }

                todaySection
                weekSection
                medicalNotice
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(
            dynamicTypeSize.isAccessibilitySize
                ? "Übersicht"
                : "RecoveryLens"
        )
        .navigationBarTitleDisplayMode(
            dynamicTypeSize.isAccessibilitySize ? .inline : .automatic
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isRefreshing {
                    ProgressView()
                        .accessibilityLabel("Health-Daten werden aktualisiert")
                } else {
                    Button {
                        Task {
                            await onRefresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Health-Daten aktualisieren")
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Heute")
                .font(.title2.bold())
            Text(
                content.today.date.formatted(
                    .dateTime
                        .weekday(.wide)
                        .day()
                        .month(.wide)
                        .locale(Locale(identifier: "de_DE"))
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var missingDataNotice: some View {
        Label {
            Text(
                "Einige Werte fehlen. RecoveryLens behandelt fehlende Daten nicht als gemessene Null."
            )
        } icon: {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
        }
        .font(.subheadline)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tageswerte")
                .font(.headline)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    stepsCard
                    energyCard
                    sleepCard
                }
            } else {
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        stepsCard
                        energyCard
                    }

                    sleepCard
                        .gridCellColumns(2)
                }
            }
        }
    }

    private var stepsCard: some View {
        MetricCard(
            title: "Schritte",
            value: formattedSteps,
            detail: content.today.steps == nil ? "Keine Daten" : nil,
            systemImage: "figure.walk",
            tint: .blue
        )
    }

    private var energyCard: some View {
        MetricCard(
            title: "Aktive Energie",
            value: formattedEnergy,
            detail: content.today.activeEnergyKilocalories == nil
                ? "Keine Daten"
                : "kcal",
            systemImage: "flame.fill",
            tint: .orange
        )
    }

    private var sleepCard: some View {
        MetricCard(
            title: "Schlaf",
            value: formattedSleep,
            detail: content.today.sleepMinutes == nil
                ? "Keine Daten"
                : "Stunden",
            systemImage: "bed.double.fill",
            tint: .indigo
        )
    }

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wochenübersicht")
                .font(.headline)

            NavigationLink {
                WeekOverviewView(
                    content: WeekOverviewContent(days: content.week)
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 32)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Letzte sieben Tage")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(
                            "\(content.workouts.count) Trainingseinheiten"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var medicalNotice: some View {
        Label {
            Text(
                "Keine medizinische Bewertung. Die dargestellten Werte dienen nur deiner persönlichen Reflexion."
            )
        } icon: {
            Image(systemName: "info.circle")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }

    private var formattedSteps: String {
        guard let steps = content.today.steps else {
            return "–"
        }

        return steps.formatted()
    }

    private var formattedEnergy: String {
        guard let energy = content.today.activeEnergyKilocalories else {
            return "–"
        }

        return Int(energy.rounded()).formatted()
    }

    private var formattedSleep: String {
        guard let minutes = content.today.sleepMinutes else {
            return "–"
        }

        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String?
    let systemImage: String
    let tint: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityContent
            } else {
                standardContent
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            icon
            titleText

            Spacer(minLength: 0)

            valueText
            detailText
        }
    }

    private var accessibilityContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            icon
            titleText
            valueText
            detailText
        }
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.title3)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }

    private var titleText: some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var valueText: some View {
        Text(value)
            .font(.title2.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder
    private var detailText: some View {
        if let detail {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    if let today = DemoData.summaries.last {
        NavigationStack {
            DashboardView(
                content: DashboardContent(
                    today: today,
                    week: DemoData.summaries
                ),
                showsMissingDataNotice: false,
                isRefreshing: false,
                onRefresh: {}
            )
        }
    }
}
