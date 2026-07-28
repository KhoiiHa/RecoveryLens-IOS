import Foundation

enum DemoData {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "de_DE")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static let referenceDate: Date = {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 7
        components.day = 28
        components.hour = 12
        return components.date!
    }()

    static let snapshot = HealthDataSnapshot(
        stepSamples: quantitySamples(values: [6_420, 8_150, 5_980, 9_230, 7_760, 10_420, 8_840]),
        activeEnergySamples: quantitySamples(values: [410, 525, 380, 610, 475, 690, 540]),
        sleepSamples: sleepSamples(),
        workouts: [
            WorkoutSummary(
                id: UUID(uuidString: "A741D0C8-56B0-4D6A-95CE-044E91E52B5F")!,
                startDate: date(dayOffset: -5, hour: 18),
                durationMinutes: 42,
                activityName: "Laufen",
                activeEnergyKilocalories: 395
            ),
            WorkoutSummary(
                id: UUID(uuidString: "5989B4CB-BA30-4A12-A3A0-0F7D8E8E1062")!,
                startDate: date(dayOffset: -2, hour: 7, minute: 30),
                durationMinutes: 35,
                activityName: "Krafttraining",
                activeEnergyKilocalories: 240
            ),
            WorkoutSummary(
                id: UUID(uuidString: "D9B67E37-A4FA-4D5D-85D9-5673245523CA")!,
                startDate: date(dayOffset: 0, hour: 8),
                durationMinutes: 28,
                activityName: "Radfahren",
                activeEnergyKilocalories: 215
            )
        ]
    )

    static let summaries = HealthSummaryAggregator(calendar: calendar).summaries(
        from: snapshot,
        endingAt: referenceDate
    )

    private static func quantitySamples(values: [Double]) -> [QuantitySample] {
        values.enumerated().map { index, value in
            QuantitySample(
                date: date(dayOffset: index - (values.count - 1), hour: 12),
                value: value
            )
        }
    }

    private static func sleepSamples() -> [SleepSample] {
        let durations = [440, 465, 410, 480, 455, 430, 470]

        return durations.enumerated().map { index, duration in
            let dayOffset = index - (durations.count - 1)
            let end = date(dayOffset: dayOffset, hour: 7)

            return SleepSample(
                startDate: end.addingTimeInterval(TimeInterval(-duration * 60)),
                endDate: end,
                state: .asleep
            )
        }
    }

    private static func date(
        dayOffset: Int,
        hour: Int,
        minute: Int = 0
    ) -> Date {
        let referenceDay = calendar.startOfDay(for: referenceDate)

        guard let day = calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: referenceDay
        ), let date = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) else {
            preconditionFailure("Die Demo-Daten konnten nicht erstellt werden.")
        }

        return date
    }
}
