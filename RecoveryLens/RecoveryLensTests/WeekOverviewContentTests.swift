import Foundation
import Testing
@testable import RecoveryLens

struct WeekOverviewContentTests {
    @Test
    func pointsOmitMissingValuesButPreserveMeasuredZero() throws {
        let firstDate = try date(dayOffset: -2)
        let secondDate = try date(dayOffset: -1)
        let thirdDate = try date(dayOffset: 0)
        let content = WeekOverviewContent(
            days: [
                summary(
                    date: thirdDate,
                    steps: 0,
                    energy: nil,
                    sleepMinutes: 420
                ),
                summary(
                    date: firstDate,
                    steps: 1_500,
                    energy: 320,
                    sleepMinutes: nil
                ),
                summary(
                    date: secondDate,
                    steps: nil,
                    energy: 0,
                    sleepMinutes: 390
                ),
            ]
        )

        #expect(content.days.map(\.date) == [
            firstDate,
            secondDate,
            thirdDate,
        ])
        #expect(content.points(for: .steps) == [
            WeekChartPoint(date: firstDate, value: 1_500),
            WeekChartPoint(date: thirdDate, value: 0),
        ])
        #expect(content.points(for: .activeEnergy) == [
            WeekChartPoint(date: firstDate, value: 320),
            WeekChartPoint(date: secondDate, value: 0),
        ])
        #expect(content.points(for: .sleep) == [
            WeekChartPoint(date: secondDate, value: 6.5),
            WeekChartPoint(date: thirdDate, value: 7),
        ])
    }

    @Test
    func workoutsAreSortedNewestFirstAndKeepMissingEnergy() throws {
        let olderWorkout = WorkoutSummary(
            id: UUID(),
            startDate: try date(dayOffset: -2, hour: 18),
            durationMinutes: 30,
            activityName: "Yoga",
            activeEnergyKilocalories: nil
        )
        let newerWorkout = WorkoutSummary(
            id: UUID(),
            startDate: try date(dayOffset: 0, hour: 8),
            durationMinutes: 45,
            activityName: "Laufen",
            activeEnergyKilocalories: 410
        )
        let content = WeekOverviewContent(
            days: [
                summary(
                    date: try date(dayOffset: -2),
                    workouts: [olderWorkout]
                ),
                summary(
                    date: try date(dayOffset: 0),
                    workouts: [newerWorkout]
                ),
            ]
        )

        #expect(content.workouts.map(\.id) == [
            newerWorkout.id,
            olderWorkout.id,
        ])
        #expect(content.workouts.last?.activeEnergyKilocalories == nil)
    }

    @Test
    func demoContentContainsSevenCompleteChartDays() {
        let content = WeekOverviewContent(days: DemoData.summaries)

        #expect(content.days.count == 7)
        #expect(content.points(for: .steps).count == 7)
        #expect(content.points(for: .activeEnergy).count == 7)
        #expect(content.points(for: .sleep).count == 7)
        #expect(content.workouts.count == 3)
    }

    private func summary(
        date: Date,
        steps: Int? = nil,
        energy: Double? = nil,
        sleepMinutes: Int? = nil,
        workouts: [WorkoutSummary] = []
    ) -> DailyHealthSummary {
        DailyHealthSummary(
            date: date,
            steps: steps,
            activeEnergyKilocalories: energy,
            sleepMinutes: sleepMinutes,
            workouts: workouts
        )
    }

    private func date(
        dayOffset: Int,
        hour: Int = 0
    ) throws -> Date {
        let startDate = DemoData.calendar.startOfDay(
            for: DemoData.referenceDate
        )
        let day = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: startDate
            )
        )
        return try #require(
            DemoData.calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: day
            )
        )
    }
}
