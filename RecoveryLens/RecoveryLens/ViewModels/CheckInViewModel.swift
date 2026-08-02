import Foundation
import Observation

@MainActor
@Observable
final class CheckInViewModel {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case saved
        case unavailable(String)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var isExistingCheckIn = false

    var energyLevel = 3 {
        didSet { draftDidChange() }
    }
    var moodLevel = 3 {
        didSet { draftDidChange() }
    }
    var note = "" {
        didSet { draftDidChange() }
    }

    private(set) var date: Date

    var canSave: Bool {
        (1...5).contains(energyLevel)
            && (1...5).contains(moodLevel)
            && note.count <= SwiftDataCheckInService.maximumNoteLength
            && isReadyToSave
            && (!isExistingCheckIn || hasUnsavedChanges)
    }

    var remainingNoteCharacters: Int {
        SwiftDataCheckInService.maximumNoteLength - note.count
    }

    private let checkInService: any CheckInService
    private let calendar: Calendar
    private var savedDraft: Draft?

    init(
        checkInService: any CheckInService,
        date: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.checkInService = checkInService
        self.date = date
        self.calendar = calendar
    }

    func load() {
        state = .loading

        do {
            guard let checkIn = try checkInService.checkIn(for: date) else {
                isExistingCheckIn = false
                state = .ready
                return
            }

            energyLevel = checkIn.energyLevel
            moodLevel = checkIn.moodLevel
            note = checkIn.note ?? ""
            isExistingCheckIn = true
            savedDraft = currentDraft
            state = .ready
        } catch {
            state = failureState(
                for: error,
                fallback: "Der Check-in konnte nicht geladen werden."
            )
        }
    }

    func save() {
        guard canSave else {
            state = .failed("Bitte prüfe deine Eingaben.")
            return
        }

        state = .loading

        do {
            let savedCheckIn = try checkInService.save(
                date: date,
                energyLevel: energyLevel,
                moodLevel: moodLevel,
                note: note
            )
            energyLevel = savedCheckIn.energyLevel
            moodLevel = savedCheckIn.moodLevel
            note = savedCheckIn.note ?? ""
            isExistingCheckIn = true
            savedDraft = currentDraft
            state = .saved
        } catch {
            state = failureState(
                for: error,
                fallback: "Der Check-in konnte nicht gespeichert werden."
            )
        }
    }

    func refreshDateIfNeeded(_ currentDate: Date) {
        guard !calendar.isDate(date, inSameDayAs: currentDate) else {
            return
        }

        date = currentDate
        energyLevel = 3
        moodLevel = 3
        note = ""
        isExistingCheckIn = false
        savedDraft = nil
        state = .idle
        load()
    }

    private var isReadyToSave: Bool {
        switch state {
        case .ready, .saved:
            true
        default:
            false
        }
    }

    private var hasUnsavedChanges: Bool {
        savedDraft != currentDraft
    }

    private var currentDraft: Draft {
        Draft(
            energyLevel: energyLevel,
            moodLevel: moodLevel,
            note: note
        )
    }

    private func draftDidChange() {
        guard state == .saved, hasUnsavedChanges else {
            return
        }

        state = .ready
    }

    private func failureState(for error: Error, fallback: String) -> State {
        let message = error.localizedDescription.isEmpty
            ? fallback
            : error.localizedDescription

        if error as? CheckInServiceError == .persistenceUnavailable {
            return .unavailable(message)
        }

        return .failed(message)
    }
}

private struct Draft: Equatable {
    let energyLevel: Int
    let moodLevel: Int
    let note: String
}
