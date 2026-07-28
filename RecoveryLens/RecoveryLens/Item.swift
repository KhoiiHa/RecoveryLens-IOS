//
//  Item.swift
//  RecoveryLens
//
//  Created by Vu Minh Khoi Ha on 28.07.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
