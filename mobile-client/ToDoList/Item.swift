//
//  Item.swift
//  ToDoList
//
//  Created by Rex Chen on 2024/10/20.
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
