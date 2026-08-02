import Foundation
import Testing
@testable import RecoveryLens

@MainActor
struct CheckInViewModelTests {
    @Test
    func loadUsesExistingCheckInValues() {
        let existingCheckIn = makeCheckIn(
            energyLevel: 2,
            moodLevel: 4,
            note: "Notiz"
        )
        let service = CheckInServiceSpy(checkInResult: existingCheckIn)
        let viewModel = makeViewModel(service: service)

        viewModel.load()

        #expect(viewModel.state == .ready)
        #expect(viewModel.isExistingCheckIn)
        #expect(viewModel.energyLevel == 2)
        #expect(viewModel.moodLevel == 4)
        #expect(viewModel.note == "Notiz")
        #expect(service.requestedDates == [DemoData.referenceDate])
    }

    @Test
    func loadKeepsDefaultsWhenNoCheckInExists() {
        let service = CheckInServiceSpy()
        let viewModel = makeViewModel(service: service)

        viewModel.load()

        #expect(viewModel.state == .ready)
        #expect(!viewModel.isExistingCheckIn)
        #expect(viewModel.energyLevel == 3)
        #expect(viewModel.moodLevel == 3)
        #expect(viewModel.note.isEmpty)
    }

    @Test
    func saveForwardsValuesAndMarksCheckInAsSaved() throws {
        let service = CheckInServiceSpy()
        let viewModel = makeViewModel(service: service)
        viewModel.load()
        viewModel.energyLevel = 5
        viewModel.moodLevel = 4
        viewModel.note = "  Fokus  "

        viewModel.save()

        let request = try #require(service.saveRequests.first)
        #expect(request.date == DemoData.referenceDate)
        #expect(request.energyLevel == 5)
        #expect(request.moodLevel == 4)
        #expect(request.note == "  Fokus  ")
        #expect(viewModel.state == .saved)
        #expect(viewModel.isExistingCheckIn)
    }

    @Test
    func invalidDraftDoesNotReachService() {
        let service = CheckInServiceSpy()
        let viewModel = makeViewModel(service: service)
        viewModel.load()
        viewModel.note = String(
            repeating: "a",
            count: SwiftDataCheckInService.maximumNoteLength + 1
        )

        viewModel.save()

        #expect(service.saveRequests.isEmpty)
        guard case .failed = viewModel.state else {
            Issue.record("Ungültige Eingaben erzeugen keinen Fehlerzustand.")
            return
        }
    }

    @Test
    func serviceErrorsRemainVisible() {
        let loadService = CheckInServiceSpy(
            checkInError: CheckInTestError.failed
        )
        let saveService = CheckInServiceSpy(
            saveError: CheckInTestError.failed
        )
        let loadViewModel = makeViewModel(service: loadService)
        let saveViewModel = makeViewModel(service: saveService)

        loadViewModel.load()
        saveViewModel.load()
        saveViewModel.save()

        assertFailure(loadViewModel.state, message: "Testfehler")
        assertFailure(saveViewModel.state, message: "Testfehler")
    }

    @Test
    func unavailablePersistenceDisablesSaving() {
        let service = CheckInServiceSpy(
            error: CheckInServiceError.persistenceUnavailable
        )
        let viewModel = makeViewModel(service: service)

        viewModel.load()

        guard case let .unavailable(message) = viewModel.state else {
            Issue.record("Der Persistence-Fehler wurde nicht separat dargestellt.")
            return
        }
        #expect(message == "Lokale Check-ins sind derzeit nicht verfügbar.")
        #expect(!viewModel.canSave)
    }

    @Test
    func savingRequiresSuccessfulLoad() {
        let idleViewModel = makeViewModel(service: CheckInServiceSpy())
        let failedViewModel = makeViewModel(
            service: CheckInServiceSpy(
                checkInError: CheckInTestError.failed
            )
        )

        failedViewModel.load()

        #expect(!idleViewModel.canSave)
        #expect(!failedViewModel.canSave)
    }

    @Test
    func existingCheckInOnlySavesActualChanges() {
        let existingCheckIn = makeCheckIn(
            energyLevel: 2,
            moodLevel: 4,
            note: "Notiz"
        )
        let service = CheckInServiceSpy(checkInResult: existingCheckIn)
        let viewModel = makeViewModel(service: service)

        viewModel.load()
        #expect(!viewModel.canSave)

        viewModel.energyLevel = 5
        #expect(viewModel.canSave)

        viewModel.save()
        #expect(viewModel.state == .saved)
        #expect(!viewModel.canSave)

        viewModel.note = "Neue Notiz"
        #expect(viewModel.state == .ready)
        #expect(viewModel.canSave)
    }

    @Test
    func refreshDateKeepsDraftWithinSameCalendarDay() throws {
        let service = CheckInServiceSpy()
        let viewModel = makeViewModel(service: service)
        viewModel.load()
        viewModel.energyLevel = 5
        viewModel.note = "Bleibt erhalten"
        let evening = try #require(
            DemoData.calendar.date(
                bySettingHour: 21,
                minute: 0,
                second: 0,
                of: DemoData.referenceDate
            )
        )

        viewModel.refreshDateIfNeeded(evening)

        #expect(viewModel.date == DemoData.referenceDate)
        #expect(viewModel.energyLevel == 5)
        #expect(viewModel.note == "Bleibt erhalten")
        #expect(service.requestedDates == [DemoData.referenceDate])
    }

    @Test
    func refreshDateLoadsDefaultsForNextCalendarDay() throws {
        let service = CheckInServiceSpy()
        let viewModel = makeViewModel(service: service)
        viewModel.load()
        viewModel.energyLevel = 5
        viewModel.moodLevel = 1
        viewModel.note = "Alter Tag"
        let nextDay = try #require(
            DemoData.calendar.date(
                byAdding: .day,
                value: 1,
                to: DemoData.referenceDate
            )
        )

        viewModel.refreshDateIfNeeded(nextDay)

        #expect(viewModel.date == nextDay)
        #expect(viewModel.energyLevel == 3)
        #expect(viewModel.moodLevel == 3)
        #expect(viewModel.note.isEmpty)
        #expect(viewModel.state == .ready)
        #expect(service.requestedDates == [DemoData.referenceDate, nextDay])
    }

    private func makeViewModel(
        service: CheckInServiceSpy
    ) -> CheckInViewModel {
        CheckInViewModel(
            checkInService: service,
            date: DemoData.referenceDate,
            calendar: DemoData.calendar
        )
    }

    private func makeCheckIn(
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) -> DailyCheckIn {
        DailyCheckIn(
            date: DemoData.referenceDate,
            energyLevel: energyLevel,
            moodLevel: moodLevel,
            note: note,
            createdAt: DemoData.referenceDate,
            updatedAt: DemoData.referenceDate
        )
    }

    private func assertFailure(
        _ state: CheckInViewModel.State,
        message: String
    ) {
        guard case let .failed(actualMessage) = state else {
            Issue.record("Der erwartete Fehlerzustand fehlt.")
            return
        }

        #expect(actualMessage == message)
    }
}

@MainActor
private final class CheckInServiceSpy: CheckInService {
    struct SaveRequest {
        let date: Date
        let energyLevel: Int
        let moodLevel: Int
        let note: String?
    }

    private let checkInResult: DailyCheckIn?
    private let checkInError: Error?
    private let saveError: Error?

    private(set) var requestedDates: [Date] = []
    private(set) var saveRequests: [SaveRequest] = []

    init(
        checkInResult: DailyCheckIn? = nil,
        error: Error? = nil,
        checkInError: Error? = nil,
        saveError: Error? = nil
    ) {
        self.checkInResult = checkInResult
        self.checkInError = checkInError ?? error
        self.saveError = saveError ?? error
    }

    func checkIn(for date: Date) throws -> DailyCheckIn? {
        requestedDates.append(date)

        if let checkInError {
            throw checkInError
        }

        return checkInResult
    }

    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn {
        saveRequests.append(
            SaveRequest(
                date: date,
                energyLevel: energyLevel,
                moodLevel: moodLevel,
                note: note
            )
        )

        if let saveError {
            throw saveError
        }

        return DailyCheckIn(
            date: date,
            energyLevel: energyLevel,
            moodLevel: moodLevel,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: DemoData.referenceDate,
            updatedAt: DemoData.referenceDate
        )
    }
}

private enum CheckInTestError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Testfehler"
    }
}
