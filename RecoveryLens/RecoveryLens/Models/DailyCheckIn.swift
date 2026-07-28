import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    @Attribute(.unique) var date: Date
    var energyLevel: Int
    var moodLevel: Int
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.date = date
        self.energyLevel = energyLevel
        self.moodLevel = moodLevel
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
