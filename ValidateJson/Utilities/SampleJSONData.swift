//
//  SampleJSONData.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation

/// Provides sample JSON data for testing and demonstration
struct SampleJSONData {
    
    static let simple = """
    {
        "name": "John Doe",
        "age": 30,
        "isActive": true
    }
    """
    
    static let nested = """
    {
        "user": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "address": {
                "street": "123 Main St",
                "city": "San Francisco",
                "state": "CA",
                "zip": "94102"
            }
        },
        "preferences": {
            "theme": "dark",
            "notifications": true,
            "language": "en"
        }
    }
    """
    
    static let withArray = """
    {
        "users": [
            {
                "id": 1,
                "name": "Alice"
            },
            {
                "id": 2,
                "name": "Bob"
            },
            {
                "id": 3,
                "name": "Charlie"
            }
        ],
        "total": 3
    }
    """
    
    static let complex = """
    {
        "company": "Tech Corp",
        "founded": 2020,
        "active": true,
        "employees": [
            {
                "id": 1,
                "name": "Alice Johnson",
                "role": "Engineer",
                "skills": ["Swift", "Python", "JavaScript"],
                "contact": {
                    "email": "alice@techcorp.com",
                    "phone": null
                }
            },
            {
                "id": 2,
                "name": "Bob Smith",
                "role": "Designer",
                "skills": ["Figma", "Sketch", "Photoshop"],
                "contact": {
                    "email": "bob@techcorp.com",
                    "phone": "555-0123"
                }
            }
        ],
        "departments": ["Engineering", "Design", "Marketing"],
        "revenue": 1500000.50,
        "public": false
    }
    """
    
    static let invalid = """
    {
        "name": "Test",
        "value": 123,
        "incomplete": 
    }
    """
    
    static let malformedBracket = """
    {
        "name": "Test",
        "items": [1, 2, 3
    }
    """
    
    /// Returns all sample data as a dictionary
    static var allSamples: [(name: String, json: String)] {
        return [
            ("Simple Object", simple),
            ("Nested Objects", nested),
            ("With Arrays", withArray),
            ("Complex Structure", complex),
            ("Invalid JSON", invalid),
            ("Malformed Bracket", malformedBracket)
        ]
    }
}
