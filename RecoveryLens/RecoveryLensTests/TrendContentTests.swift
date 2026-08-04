import Foundation
import Testing
@testable import RecoveryLens

struct TrendContentTests {
    @Test
    func pointsPreserveMeasuredZeroAndOmitMissingValues() throws {
        let firstDate = try date(dayOffset: -2)
        let secondDate = try date(dayOffset: -1)
        let thirdDate = try date(dayOffset: 0)
        let content = TrendContent(
            days: [
                summary(date: thirdDate, steps: 0),
                summary(date: firstDate, steps: 1_500),
                summary(date: secondDate, steps: nil),
            ],
            checkIns: [],
            calendar: DemoData.calendar
        )

        #expect(content.points(for: .steps) == [
            TrendChartPoint(date: firstDate, value: 1_500),
            TrendChartPoint(date: thirdDate, value: 0),
        ])
    }

    @Test
    func medianHandlesOddAndEvenDataCounts() throws {
        let days = try [100, 400, 200, 300].enumerated().map { index, steps in
            summary(
                date: try date(dayOffset: index - 3),
                steps: steps
            )
        }
        let evenContent = TrendContent(days: days, checkIns: [])
        let oddContent = TrendContent(days: Array(days.dropLast()), checkIns: [])

        #expect(evenContent.median(for: .steps) == 250)
        #expect(oddContent.median(for: .steps) == 200)
        #expect(TrendContent(days: [], checkIns: []).median(for: .steps) == nil)
    }

    @Test
    func comparisonMatchesCheckInsByLocalCalendarDay() throws {
        let day = try date(dayOffset: 0)
        let evening = try #require(
            DemoData.calendar.date(
                bySettingHour: 20,
                minute: 30,
                second: 0,
                of: day
            )
        )
        let content = TrendContent(
            days: [summary(date: day, sleepMinutes: 450)],
            checkIns: [
                DailyCheckInSummary(
                    date: evening,
                    energyLevel: 4,
                    moodLevel: 3
                ),
            ],
            calendar: DemoData.calendar
        )

        #expect(content.comparisonPoints(for: .sleep) == [
            EnergyComparisonPoint(
                date: day,
                metricValue: 7.5,
                energyLevel: 4
            ),
        ])
    }

    @Test
    func comparisonRequiresFivePairedDays() throws {
        let days = try (0..<5).map { index in
            summary(
                date: try date(dayOffset: index - 4),
                steps: 2_000 + index
            )
        }
        let fourCheckIns = try (0..<4).map { index in
            DailyCheckInSummary(
                date: try date(dayOffset: index - 3),
                energyLevel: 3,
                moodLevel: 3
            )
        }
        let fiveCheckIns = fourCheckIns + [
            DailyCheckInSummary(
                date: try date(dayOffset: -4),
                energyLevel: 4,
                moodLevel: 4
            ),
        ]

        #expect(
            !TrendContent(days: days, checkIns: fourCheckIns)
                .hasSufficientComparisonData(for: .steps)
        )
        #expect(
            TrendContent(days: days, checkIns: fiveCheckIns)
                .hasSufficientComparisonData(for: .steps)
        )
    }

    @Test
    func healthAvailabilityIgnoresCheckInsWithoutHealthValues() throws {
        let day = try date(dayOffset: 0)
        let content = TrendContent(
            days: [summary(date: day)],
            checkIns: [
                DailyCheckInSummary(
                    date: day,
                    energyLevel: 5,
                    moodLevel: 5
                ),
            ]
        )

        #expect(!content.hasAnyHealthData)
    }

    private func summary(
        date: Date,
        steps: Int? = nil,
        energy: Double? = nil,
        sleepMinutes: Int? = nil
    ) -> DailyHealthSummary {
        DailyHealthSummary(
            date: date,
            steps: steps,
            activeEnergyKilocalories: energy,
            sleepMinutes: sleepMinutes,
            workouts: []
        )
    }

    private func date(dayOffset: Int) throws -> Date {
        let referenceDay = DemoData.calendar.startOfDay(
            for: DemoData.referenceDate
        )
        return try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: referenceDay
            )
        )
    }
}
