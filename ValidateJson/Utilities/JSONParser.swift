//
//  JSONParser.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation

/// Parses JSON strings into tree node structures
struct JSONParser {
    
    /// Parses a JSON string and returns the root node(s)
    static func parse(_ jsonString: String) -> [JSONNode]? {
        let validationResult = JSONValidator.validate(jsonString)
        
        guard case .valid(let parsedObject) = validationResult else {
            return nil
        }
        
        return [buildNode(from: parsedObject, key: nil)]
    }
    
    /// Recursively builds a single node (with correctly nested children) from a parsed JSON value.
    /// - Note: The previous implementation built a node's children by re-invoking the top-level
    ///   builder and wrapping the result again, which produced a duplicate "phantom" node one
    ///   level below every object/array/primitive. This version builds exactly one node per value.
    private static func buildNode(from object: Any, key: String?) -> JSONNode {
        if let dictionary = object as? [String: Any] {
            let children = dictionary
                .map { buildNode(from: $0.value, key: $0.key) }
                .sorted { ($0.key ?? "") < ($1.key ?? "") } // Sort alphabetically
            return JSONNode(key: key, value: .object(dictionary), children: children)
            
        } else if let array = object as? [Any] {
            let children = array.enumerated().map { index, element in
                buildNode(from: element, key: "[\(index)]")
            }
            return JSONNode(key: key, value: .array(array), children: children)
            
        } else {
            return JSONNode(key: key, value: primitiveValue(from: object))
        }
    }
    
    /// Converts a leaf JSON value (as produced by `JSONSerialization`) into a `JSONValue`.
    /// - Note: Booleans must be checked *before* numeric types. `NSNumber` instances backed by
    ///   `CFBoolean` (i.e. JSON `true`/`false`) can successfully bridge to `Double` in Swift,
    ///   so checking numeric casts first previously caused every boolean to be misread as `1.0`/`0.0`.
    private static func primitiveValue(from object: Any) -> JSONValue {
        if let string = object as? String {
            return .string(string)
        } else if let number = object as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        } else if object is NSNull {
            return .null
        } else {
            // Fallback to string representation
            return .string("\(object)")
        }
    }
    
    /// Convenience method to parse and get a single root node
    static func parseToRoot(_ jsonString: String) -> JSONNode? {
        guard let nodes = parse(jsonString), let firstNode = nodes.first else {
            return nil
        }
        return firstNode
    }
}
