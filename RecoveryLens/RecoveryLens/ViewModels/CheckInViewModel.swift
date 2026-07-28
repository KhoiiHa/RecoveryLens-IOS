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
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var isExistingCheckIn = false

    var energyLevel = 3
    var moodLevel = 3
    var note = ""

    let date: Date

    var canSave: Bool {
        (1...5).contains(energyLevel)
            && (1...5).contains(moodLevel)
            && note.count <= SwiftDataCheckInService.maximumNoteLength
            && state != .loading
    }

    var remainingNoteCharacters: Int {
        SwiftDataCheckInService.maximumNoteLength - note.count
    }

    private let checkInService: any CheckInService

    init(
        checkInService: any CheckInService,
        date: Date = Date()
    ) {
        self.checkInService = checkInService
        self.date = date
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
            state = .ready
        } catch {
            state = .failed(
                error.localizedDescription.isEmpty
                    ? "Der Check-in konnte nicht geladen werden."
                    : error.localizedDescription
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
            state = .saved
        } catch {
            state = .failed(
                error.localizedDescription.isEmpty
                    ? "Der Check-in konnte nicht gespeichert werden."
                    : error.localizedDescription
            )
        }
    }
}
