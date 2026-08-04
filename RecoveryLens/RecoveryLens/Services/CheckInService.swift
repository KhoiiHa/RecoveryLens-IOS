import Foundation
import SwiftData

enum CheckInValidationError: Error, Equatable, LocalizedError {
    case invalidEnergyLevel
    case invalidMoodLevel
    case noteTooLong(maximumLength: Int)

    var errorDescription: String? {
        switch self {
        case .invalidEnergyLevel:
            "Das Energieempfinden muss zwischen 1 und 5 liegen."
        case .invalidMoodLevel:
            "Die Stimmung muss zwischen 1 und 5 liegen."
        case let .noteTooLong(maximumLength):
            "Die Notiz darf höchstens \(maximumLength) Zeichen enthalten."
        }
    }
}

enum CheckInServiceError: Error, Equatable, LocalizedError {
    case persistenceUnavailable

    var errorDescription: String? {
        "Lokale Check-ins sind derzeit nicht verfügbar."
    }
}

@MainActor
protocol CheckInService {
    func checkIn(for date: Date) throws -> DailyCheckIn?
    func checkInSummaries(from startDate: Date, to endDate: Date) throws
        -> [DailyCheckInSummary]

    @discardableResult
    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn
}

extension CheckInService {
    func checkInSummaries(from startDate: Date, to endDate: Date) throws
        -> [DailyCheckInSummary] {
        []
    }
}

@MainActor
struct UnavailableCheckInService: CheckInService {
    func checkIn(for date: Date) throws -> DailyCheckIn? {
        throw CheckInServiceError.persistenceUnavailable
    }

    func checkInSummaries(from startDate: Date, to endDate: Date) throws
        -> [DailyCheckInSummary] {
        throw CheckInServiceError.persistenceUnavailable
    }

    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn {
        throw CheckInServiceError.persistenceUnavailable
    }
}

@MainActor
final class SwiftDataCheckInService: CheckInService {
    static let maximumNoteLength = 280

    private let modelContext: ModelContext
    private let calendar: Calendar
    private let now: () -> Date

    init(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.modelContext = modelContext
        self.calendar = calendar
        self.now = now
    }

    func checkIn(for date: Date) throws -> DailyCheckIn? {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(
            byAdding: .day,
            value: 1,
            to: dayStart
        ) else {
            return nil
        }

        var descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate {
                $0.date >= dayStart && $0.date < dayEnd
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func checkInSummaries(
        from startDate: Date,
        to endDate: Date
    ) throws -> [DailyCheckInSummary] {
        guard startDate < endDate else {
            return []
        }

        let rangeStart = calendar.startOfDay(for: startDate)
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate {
                $0.date >= rangeStart && $0.date < endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor).map {
            DailyCheckInSummary(
                date: $0.date,
                energyLevel: $0.energyLevel,
                moodLevel: $0.moodLevel
            )
        }
    }

    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn {
        let normalizedNote = normalizedNote(note)
        try validate(
            energyLevel: energyLevel,
            moodLevel: moodLevel,
            note: normalizedNote
        )

        let dayStart = calendar.startOfDay(for: date)
        let timestamp = now()

        let savedCheckIn: DailyCheckIn
        if let existingCheckIn = try checkIn(for: dayStart) {
            existingCheckIn.energyLevel = energyLevel
            existingCheckIn.moodLevel = moodLevel
            existingCheckIn.note = normalizedNote
            existingCheckIn.updatedAt = timestamp
            savedCheckIn = existingCheckIn
        } else {
            let newCheckIn = DailyCheckIn(
                date: dayStart,
                energyLevel: energyLevel,
                moodLevel: moodLevel,
                note: normalizedNote,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            modelContext.insert(newCheckIn)
            savedCheckIn = newCheckIn
        }

        try modelContext.save()
        return savedCheckIn
    }

    private func validate(
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws {
        guard (1...5).contains(energyLevel) else {
            throw CheckInValidationError.invalidEnergyLevel
        }
        guard (1...5).contains(moodLevel) else {
            throw CheckInValidationError.invalidMoodLevel
        }
        guard note?.count ?? 0 <= Self.maximumNoteLength else {
            throw CheckInValidationError.noteTooLong(
                maximumLength: Self.maximumNoteLength
            )
        }
    }

    private func normalizedNote(_ note: String?) -> String? {
        let trimmedNote = note?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedNote?.isEmpty == false ? trimmedNote : nil
    }
}
