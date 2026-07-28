import Foundation
import Testing
@testable import RecoveryLens

struct RecoveryLensTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    @Test
    func summariesCoverSevenDaysInChronologicalOrder() throws {
        let referenceDate = try date(year: 2026, month: 7, day: 28, hour: 15)
        let expectedFirstDate = try date(year: 2026, month: 7, day: 22)
        let expectedLastDate = try date(year: 2026, month: 7, day: 28)

        let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
            from: .empty,
            endingAt: referenceDate
        )

        #expect(summaries.count == 7)
        #expect(summaries.first?.date == expectedFirstDate)
        #expect(summaries.last?.date == expectedLastDate)
    }

    @Test
    func quantitiesAndWorkoutsAreAggregatedByLocalDay() throws {
        let firstWorkout = WorkoutSummary(
            id: UUID(),
            startDate: try date(year: 2026, month: 7, day: 28, hour: 18),
            durationMinutes: 30,
            activityName: "Laufen",
            activeEnergyKilocalories: 280
        )
        let earlierWorkout = WorkoutSummary(
            id: UUID(),
            startDate: try date(year: 2026, month: 7, day: 28, hour: 7),
            durationMinutes: 20,
            activityName: "Yoga",
            activeEnergyKilocalories: nil
        )
        let snapshot = HealthDataSnapshot(
            stepSamples: [
                QuantitySample(
                    date: try date(year: 2026, month: 7, day: 28, hour: 8),
                    value: 1_200
                ),
                QuantitySample(
                    date: try date(year: 2026, month: 7, day: 28, hour: 17),
                    value: 2_345
                ),
                QuantitySample(
                    date: try date(year: 2026, month: 7, day: 21, hour: 12),
                    value: 9_999
                )
            ],
            activeEnergySamples: [
                QuantitySample(
                    date: try date(year: 2026, month: 7, day: 28, hour: 12),
                    value: 421.5
                )
            ],
            sleepSamples: [],
            workouts: [firstWorkout, earlierWorkout]
        )

        let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
            from: snapshot,
            endingAt: try date(year: 2026, month: 7, day: 28, hour: 22)
        )
        let today = try #require(summaries.last)

        #expect(today.steps == 3_545)
        #expect(today.activeEnergyKilocalories == 421.5)
        #expect(today.workouts.map(\.activityName) == ["Yoga", "Laufen"])
    }

    @Test
    func missingValuesRemainNilWhileMeasuredZeroIsPreserved() throws {
        let snapshot = HealthDataSnapshot(
            stepSamples: [
                QuantitySample(
                    date: try date(year: 2026, month: 7, day: 28, hour: 12),
                    value: 0
                )
            ],
            activeEnergySamples: [],
            sleepSamples: [],
            workouts: []
        )

        let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
            from: snapshot,
            endingAt: try date(year: 2026, month: 7, day: 28, hour: 12)
        )
        let today = try #require(summaries.last)

        #expect(today.steps == 0)
        #expect(today.activeEnergyKilocalories == nil)
        #expect(today.sleepMinutes == nil)
        #expect(today.workouts.isEmpty)
    }

    @Test
    func overlappingSleepIsCountedOnceAndAwakeTimeIsExcluded() throws {
        let snapshot = HealthDataSnapshot(
            stepSamples: [],
            activeEnergySamples: [],
            sleepSamples: [
                SleepSample(
                    startDate: try date(year: 2026, month: 7, day: 28),
                    endDate: try date(year: 2026, month: 7, day: 28, hour: 4),
                    state: .asleep
                ),
                SleepSample(
                    startDate: try date(year: 2026, month: 7, day: 28, hour: 3),
                    endDate: try date(year: 2026, month: 7, day: 28, hour: 6),
                    state: .asleep
                ),
                SleepSample(
                    startDate: try date(
                        year: 2026,
                        month: 7,
                        day: 28,
                        hour: 4,
                        minute: 10
                    ),
                    endDate: try date(
                        year: 2026,
                        month: 7,
                        day: 28,
                        hour: 4,
                        minute: 40
                    ),
                    state: .awake
                )
            ],
            workouts: []
        )

        let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
            from: snapshot,
            endingAt: try date(year: 2026, month: 7, day: 28, hour: 12)
        )

        #expect(summaries.last?.sleepMinutes == 330)
    }

    @Test
    func sleepAcrossMidnightIsSplitAtLocalDayBoundaries() throws {
        let snapshot = HealthDataSnapshot(
            stepSamples: [],
            activeEnergySamples: [],
            sleepSamples: [
                SleepSample(
                    startDate: try date(year: 2026, month: 7, day: 27, hour: 23),
                    endDate: try date(year: 2026, month: 7, day: 28, hour: 7),
                    state: .asleep
                )
            ],
            workouts: []
        )

        let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
            from: snapshot,
            endingAt: try date(year: 2026, month: 7, day: 28, hour: 12)
        )

        #expect(summaries[summaries.count - 2].sleepMinutes == 60)
        #expect(summaries.last?.sleepMinutes == 420)
    }

    @Test
    func emptyOrInvalidDayCountReturnsNoSummaries() throws {
        let referenceDate = try date(year: 2026, month: 7, day: 28)
        let aggregator = HealthSummaryAggregator(calendar: calendar)

        #expect(
            aggregator.summaries(
                from: .empty,
                endingAt: referenceDate,
                dayCount: 0
            ).isEmpty
        )
        #expect(
            aggregator.summaries(
                from: .empty,
                endingAt: referenceDate,
                dayCount: -1
            ).isEmpty
        )
    }

    @Test
    func demoDataIsDeterministicAndComplete() {
        #expect(DemoData.summaries.count == 7)
        #expect(DemoData.summaries.last?.steps == 8_840)
        #expect(DemoData.summaries.last?.sleepMinutes == 420)
        #expect(DemoData.summaries.flatMap(\.workouts).count == 3)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) throws -> Date {
        try #require(
            calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            )
        )
    }
}
