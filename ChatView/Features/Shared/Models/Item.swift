//
//  Item.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-08.
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
