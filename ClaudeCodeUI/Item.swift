//
//  Item.swift
//  ClaudeCodeUI
//
//  Created by Sami Hindi on 05.01.2026.
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
