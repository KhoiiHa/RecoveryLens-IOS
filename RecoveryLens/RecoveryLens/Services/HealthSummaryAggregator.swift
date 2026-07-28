import Foundation

struct HealthSummaryAggregator {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func summaries(
        from snapshot: HealthDataSnapshot,
        endingAt referenceDate: Date,
        dayCount: Int = 7
    ) -> [DailyHealthSummary] {
        guard dayCount > 0 else {
            return []
        }

        let endDay = calendar.startOfDay(for: referenceDate)

        return (0..<dayCount).reversed().compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: endDay),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }

            return DailyHealthSummary(
                date: day,
                steps: summedSteps(in: snapshot.stepSamples, on: day),
                activeEnergyKilocalories: summedValue(
                    in: snapshot.activeEnergySamples,
                    on: day
                ),
                sleepMinutes: sleepMinutes(
                    in: snapshot.sleepSamples,
                    from: day,
                    to: nextDay
                ),
                workouts: snapshot.workouts
                    .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
                    .sorted { $0.startDate < $1.startDate }
            )
        }
    }

    private func summedSteps(in samples: [QuantitySample], on day: Date) -> Int? {
        guard let value = summedValue(in: samples, on: day) else {
            return nil
        }

        return Int(value.rounded())
    }

    private func summedValue(in samples: [QuantitySample], on day: Date) -> Double? {
        let values = samples
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .map(\.value)

        guard !values.isEmpty else {
            return nil
        }

        return values.reduce(0, +)
    }

    private func sleepMinutes(
        in samples: [SleepSample],
        from dayStart: Date,
        to dayEnd: Date
    ) -> Int? {
        let asleepIntervals = mergedIntervals(
            samples
                .filter { $0.state == .asleep }
                .compactMap { clippedInterval(for: $0, from: dayStart, to: dayEnd) }
        )

        guard !asleepIntervals.isEmpty else {
            return nil
        }

        let awakeIntervals = mergedIntervals(
            samples
                .filter { $0.state == .awake }
                .compactMap { clippedInterval(for: $0, from: dayStart, to: dayEnd) }
        )

        let asleepDuration = asleepIntervals.reduce(0) {
            $0 + $1.end.timeIntervalSince($1.start)
        }
        let awakeDuration = overlapDuration(
            between: asleepIntervals,
            and: awakeIntervals
        )
        let effectiveDuration = max(0, asleepDuration - awakeDuration)

        return Int((effectiveDuration / 60).rounded())
    }

    private func clippedInterval(
        for sample: SleepSample,
        from rangeStart: Date,
        to rangeEnd: Date
    ) -> DateInterval? {
        let start = max(sample.startDate, rangeStart)
        let end = min(sample.endDate, rangeEnd)

        guard start < end else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }

    private func mergedIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        let sortedIntervals = intervals.sorted { $0.start < $1.start }

        return sortedIntervals.reduce(into: []) { result, interval in
            guard let last = result.last else {
                result.append(interval)
                return
            }

            if interval.start <= last.end {
                result[result.count - 1] = DateInterval(
                    start: last.start,
                    end: max(last.end, interval.end)
                )
            } else {
                result.append(interval)
            }
        }
    }

    private func overlapDuration(
        between firstIntervals: [DateInterval],
        and secondIntervals: [DateInterval]
    ) -> TimeInterval {
        firstIntervals.reduce(0) { total, firstInterval in
            total + secondIntervals.reduce(0) { subtotal, secondInterval in
                let start = max(firstInterval.start, secondInterval.start)
                let end = min(firstInterval.end, secondInterval.end)
                return subtotal + max(0, end.timeIntervalSince(start))
            }
        }
    }
}
