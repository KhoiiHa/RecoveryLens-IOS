import Foundation
import SwiftData
import Testing
@testable import RecoveryLens

@Suite(.serialized)
@MainActor
struct CheckInServiceTests {
    @Test
    func saveCreatesAndUpdatesOneCheckInPerLocalDay() throws {
        let container = try makeContainer()
        var currentTime = DemoData.referenceDate
        let service = SwiftDataCheckInService(
            modelContext: container.mainContext,
            calendar: DemoData.calendar,
            now: { currentTime }
        )

        let firstCheckIn = try service.save(
            date: DemoData.referenceDate,
            energyLevel: 2,
            moodLevel: 3,
            note: "  Ruhiger Tag  "
        )
        let createdAt = firstCheckIn.createdAt
        #expect(firstCheckIn.note == "Ruhiger Tag")
        currentTime = try #require(
            DemoData.calendar.date(
                byAdding: .minute,
                value: 30,
                to: DemoData.referenceDate
            )
        )

        let updatedCheckIn = try service.save(
            date: DemoData.referenceDate,
            energyLevel: 4,
            moodLevel: 5,
            note: String(repeating: " ", count: 300)
        )
        let allCheckIns = try container.mainContext.fetch(
            FetchDescriptor<DailyCheckIn>()
        )

        #expect(allCheckIns.count == 1)
        #expect(updatedCheckIn.persistentModelID == firstCheckIn.persistentModelID)
        #expect(updatedCheckIn.date == DemoData.calendar.startOfDay(
            for: DemoData.referenceDate
        ))
        #expect(updatedCheckIn.energyLevel == 4)
        #expect(updatedCheckIn.moodLevel == 5)
        #expect(updatedCheckIn.note == nil)
        #expect(updatedCheckIn.createdAt == createdAt)
        #expect(updatedCheckIn.updatedAt == currentTime)
    }

    @Test
    func checkInReturnsNilForMissingDayAndFindsSameCalendarDay() throws {
        let container = try makeContainer()
        let service = makeService(container: container)
        let morning = try #require(
            DemoData.calendar.date(
                bySettingHour: 8,
                minute: 0,
                second: 0,
                of: DemoData.referenceDate
            )
        )
        let evening = try #require(
            DemoData.calendar.date(
                bySettingHour: 20,
                minute: 0,
                second: 0,
                of: DemoData.referenceDate
            )
        )

        #expect(try service.checkIn(for: morning) == nil)
        _ = try service.save(
            date: morning,
            energyLevel: 3,
            moodLevel: 4,
            note: nil
        )

        #expect(try service.checkIn(for: evening) != nil)
    }

    @Test
    func checkInSummariesReturnOnlyRequestedDaysInOrder() throws {
        let container = try makeContainer()
        let service = makeService(container: container)
        let olderDate = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: -3,
                to: DemoData.referenceDate
            )
        )
        let includedDate = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: -1,
                to: DemoData.referenceDate
            )
        )
        let rangeEnd = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: 1,
                to: DemoData.calendar.startOfDay(for: DemoData.referenceDate)
            )
        )

        insertCheckIn(
            date: DemoData.referenceDate,
            energyLevel: 4,
            moodLevel: 5,
            into: container.mainContext
        )
        insertCheckIn(
            date: olderDate,
            energyLevel: 2,
            moodLevel: 3,
            into: container.mainContext
        )
        insertCheckIn(
            date: includedDate,
            energyLevel: 3,
            moodLevel: 4,
            into: container.mainContext
        )
        try container.mainContext.save()

        let summaries = try service.checkInSummaries(
            from: includedDate,
            to: rangeEnd
        )

        #expect(summaries == [
            DailyCheckInSummary(
                date: DemoData.calendar.startOfDay(for: includedDate),
                energyLevel: 3,
                moodLevel: 4
            ),
            DailyCheckInSummary(
                date: DemoData.calendar.startOfDay(
                    for: DemoData.referenceDate
                ),
                energyLevel: 4,
                moodLevel: 5
            ),
        ])
    }

    @Test
    func saveValidatesRatingsAndNoteLength() throws {
        let service = makeService(container: try makeContainer())

        #expect(throws: CheckInValidationError.invalidEnergyLevel) {
            try service.save(
                date: DemoData.referenceDate,
                energyLevel: 0,
                moodLevel: 3,
                note: nil
            )
        }
        #expect(throws: CheckInValidationError.invalidMoodLevel) {
            try service.save(
                date: DemoData.referenceDate,
                energyLevel: 3,
                moodLevel: 6,
                note: nil
            )
        }
        #expect(
            throws: CheckInValidationError.noteTooLong(
                maximumLength: SwiftDataCheckInService.maximumNoteLength
            )
        ) {
            try service.save(
                date: DemoData.referenceDate,
                energyLevel: 3,
                moodLevel: 3,
                note: String(
                    repeating: "a",
                    count: SwiftDataCheckInService.maximumNoteLength + 1
                )
            )
        }
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: DailyCheckIn.self,
            configurations: configuration
        )
    }

    private func makeService(
        container: ModelContainer
    ) -> SwiftDataCheckInService {
        SwiftDataCheckInService(
            modelContext: container.mainContext,
            calendar: DemoData.calendar,
            now: { DemoData.referenceDate }
        )
    }

    private func insertCheckIn(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        into context: ModelContext
    ) {
        let day = DemoData.calendar.startOfDay(for: date)
        context.insert(
            DailyCheckIn(
                date: day,
                energyLevel: energyLevel,
                moodLevel: moodLevel,
                note: nil,
                createdAt: DemoData.referenceDate,
                updatedAt: DemoData.referenceDate
            )
        )
    }
}
