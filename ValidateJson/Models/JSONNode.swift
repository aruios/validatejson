//
//  JSONNode.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation

/// Represents a node in the JSON tree structure
@Observable
class JSONNode: Identifiable, Equatable {
    let id = UUID()
    let key: String?
    let value: JSONValue
    var isExpanded: Bool = true
    var children: [JSONNode] = []

    /// Reference identity is sufficient for SwiftUI's onChange/diffing purposes.
    static func == (lhs: JSONNode, rhs: JSONNode) -> Bool {
        lhs.id == rhs.id
    }
    
    init(key: String? = nil, value: JSONValue, children: [JSONNode] = []) {
        self.key = key
        self.value = value
        self.children = children
    }
    
    /// Display name for the node
    var displayName: String {
        if let key = key {
            return key
        }
        return value.displayType
    }
    
    /// The actual value to display (for leaf nodes)
    var displayValue: String? {
        switch value {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return "\(num)"
        case .bool(let bool):
            return "\(bool)"
        case .null:
            return "null"
        case .object, .array:
            return nil // Objects and arrays don't show values directly
        }
    }
    
    /// Icon name based on value type
    var iconName: String {
        switch value {
        case .object:
            return "curlybraces"
        case .array:
            return "list.bullet"
        case .string:
            return "textformat.abc"
        case .number:
            return "number"
        case .bool:
            return "toggle.left"
        case .null:
            return "questionmark.circle"
        }
    }
    
    /// Whether this node can be expanded
    var isExpandable: Bool {
        return !children.isEmpty
    }
    
    /// Count display for containers (e.g., "3 items"). Shown for objects/arrays even when empty
    /// (e.g. "0 properties"), independent of whether the node is currently expandable.
    var countDisplay: String? {
        let count = children.count
        switch value {
        case .object:
            return count == 1 ? "1 property" : "\(count) properties"
        case .array:
            return count == 1 ? "1 item" : "\(count) items"
        default:
            return nil
        }
    }
}

/// Represents different JSON value types
enum JSONValue {
    case object([String: Any])
    case array([Any])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    
    var displayType: String {
        switch self {
        case .object:
            return "Object"
        case .array:
            return "Array"
        case .string:
            return "String"
        case .number:
            return "Number"
        case .bool:
            return "Boolean"
        case .null:
            return "Null"
        }
    }
}
