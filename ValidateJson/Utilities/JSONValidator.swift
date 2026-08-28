//
//  JSONValidator.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation

/// Validates JSON strings and provides detailed error information
struct JSONValidator {
    
    /// Validates a JSON string and returns the result
    static func validate(_ jsonString: String) -> JSONValidationResult {
        // Check for empty input
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalid(errors: [
                JSONParseError(
                    type: .emptyInput,
                    message: "JSON input is empty",
                    line: nil,
                    column: nil
                )
            ])
        }
        
        // Try to parse the JSON
        guard let data = jsonString.data(using: .utf8) else {
            return .invalid(errors: [
                JSONParseError(
                    type: .invalidFormat,
                    message: "Unable to convert string to data",
                    line: nil,
                    column: nil
                )
            ])
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            
            // Additional validation: check for duplicate keys (optional but useful)
            if let duplicateErrors = checkForDuplicateKeys(in: jsonString) {
                // Still valid JSON, but warn about duplicates
                return .valid(parsedObject: jsonObject)
            }
            
            return .valid(parsedObject: jsonObject)
            
        } catch let error as NSError {
            let parseError = parseNSError(error, jsonString: jsonString)
            return .invalid(errors: [parseError])
        }
    }
    
    /// Converts NSError to our JSONParseError with better formatting
    private static func parseNSError(_ error: NSError, jsonString: String) -> JSONParseError {
        let errorMessage = error.localizedDescription
        
        // Try to extract line and column information from the error
        var line: Int?
        var column: Int?
        
        // NSJSONSerialization sometimes includes position information
        if let errorString = error.userInfo["NSDebugDescription"] as? String {
            // Try to extract character position
            if let range = errorString.range(of: "around character (\\d+)", options: .regularExpression),
               let numberString = errorString[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().first,
               let position = Int(String(numberString)) {
                let lineAndColumn = getLineAndColumn(for: position, in: jsonString)
                line = lineAndColumn.line
                column = lineAndColumn.column
            }
        }
        
        // Determine error type based on message
        let errorType: JSONParseError.ErrorType
        let cleanMessage: String
        
        if errorMessage.contains("Unexpected character") || errorMessage.contains("Invalid value") {
            errorType = .unexpectedCharacter
            cleanMessage = "Unexpected character found"
        } else if errorMessage.contains("badly formed") || errorMessage.contains("JSON text") {
            errorType = .syntaxError
            cleanMessage = "Syntax error in JSON"
        } else if errorMessage.contains("Unterminated") {
            errorType = .missingBrace
            cleanMessage = "Unterminated object or array"
        } else {
            errorType = .invalidFormat
            cleanMessage = errorMessage
        }
        
        return JSONParseError(
            type: errorType,
            message: cleanMessage,
            line: line,
            column: column
        )
    }
    
    /// Calculates line and column from character position
    private static func getLineAndColumn(for position: Int, in string: String) -> (line: Int, column: Int) {
        var line = 1
        var column = 1
        var currentPos = 0
        
        for char in string {
            if currentPos >= position {
                break
            }
            
            if char == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            
            currentPos += 1
        }
        
        return (line, column)
    }
    
    /// Checks for duplicate keys in JSON objects (warning, not error)
    private static func checkForDuplicateKeys(in jsonString: String) -> [JSONParseError]? {
        // This is a simplified check - a more robust implementation would parse the JSON manually
        // For Phase 1, we'll skip this and potentially add it later
        return nil
    }
    
    /// Formats JSON string with proper indentation
    static func formatJSON(_ jsonString: String) -> String? {
        // `.fragmentsAllowed` is required on both read and write so that a valid top-level
        // primitive (e.g. a bare `"hello"` or `42`, which `validate` already accepts) can also
        // be formatted. Without it, JSONSerialization only accepts/emits objects and arrays,
        // silently failing (returning nil) for otherwise-valid fragment JSON.
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]),
              let formattedString = String(data: formattedData, encoding: .utf8) else {
            return nil
        }
        
        return formattedString
    }
}
