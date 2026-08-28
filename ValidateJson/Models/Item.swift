//
//  Item.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
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
