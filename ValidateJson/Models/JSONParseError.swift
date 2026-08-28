//
//  JSONParseError.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation

/// Represents errors that can occur during JSON parsing and validation
struct JSONParseError: Identifiable {
    let id = UUID()
    let type: ErrorType
    let message: String
    let line: Int?
    let column: Int?
    
    enum ErrorType {
        case syntaxError
        case invalidFormat
        case unexpectedCharacter
        case missingBrace
        case missingBracket
        case invalidValue
        case duplicateKey
        case emptyInput
        
        var icon: String {
            switch self {
            case .syntaxError, .invalidFormat:
                return "exclamationmark.triangle.fill"
            case .unexpectedCharacter, .invalidValue:
                return "xmark.circle.fill"
            case .missingBrace, .missingBracket:
                return "curlybraces.square.fill"
            case .duplicateKey:
                return "doc.on.doc.fill"
            case .emptyInput:
                return "doc.text.fill"
            }
        }
        
        var color: String {
            switch self {
            case .emptyInput:
                return "gray"
            case .duplicateKey:
                return "orange"
            default:
                return "red"
            }
        }
    }
    
    var fullMessage: String {
        var msg = message
        if let line = line, let column = column {
            msg += " (Line \(line), Column \(column))"
        } else if let line = line {
            msg += " (Line \(line))"
        }
        return msg
    }
}

/// Result of JSON validation
enum JSONValidationResult {
    case valid(parsedObject: Any)
    case invalid(errors: [JSONParseError])
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errors: [JSONParseError] {
        if case .invalid(let errors) = self {
            return errors
        }
        return []
    }
}
