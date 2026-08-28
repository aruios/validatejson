//
//  ValidateJsonTests.swift
//  ValidateJsonTests
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 6: Testing & Bug Fixes
//
//  Covers: various JSON structures, invalid JSON, large JSON files, edge cases
//  (empty containers, null values, special/unicode characters), and regression
//  tests for bugs discovered and fixed during this phase:
//
//    1. JSONParser previously built a "phantom" duplicate node one level below
//       every object/array/primitive (double-nesting bug).
//    2. JSONParser previously misread JSON booleans as numbers (1.0/0.0) because
//       the `Double` cast was attempted before the `Bool` cast.
//    3. JSONValidator.formatJSON previously failed (returned nil) for valid
//       top-level primitive fragments (e.g. a bare `"hello"` or `42`).
//    4. JSONNode.countDisplay previously hid the count for empty objects/arrays
//       (e.g. "0 properties") because it was gated behind `isExpandable`.
//

import Testing
@testable import ValidateJson

@Suite("JSON Validator Tests")
struct JSONValidatorTests {

    @Test("Validate simple valid JSON")
    func validateSimpleJSON() async throws {
        let result = JSONValidator.validate(SampleJSONData.simple)
        #expect(result.isValid, "Simple JSON should be valid")
        #expect(result.errors.isEmpty, "Should have no errors")
    }

    @Test("Validate nested, array, and complex samples")
    func validateVariousStructures() async throws {
        for sample in [SampleJSONData.nested, SampleJSONData.withArray, SampleJSONData.complex] {
            let result = JSONValidator.validate(sample)
            #expect(result.isValid, "Sample should be valid JSON")
        }
    }

    @Test("Validate invalid JSON (missing closing brace)")
    func validateInvalidJSON() async throws {
        let result = JSONValidator.validate(SampleJSONData.invalid)
        #expect(!result.isValid, "Invalid JSON should not be valid")
        #expect(!result.errors.isEmpty, "Should have errors")
    }

    @Test("Validate malformed bracket JSON")
    func validateMalformedBracket() async throws {
        let result = JSONValidator.validate(SampleJSONData.malformedBracket)
        #expect(!result.isValid, "Malformed bracket JSON should be invalid")
        #expect(!result.errors.isEmpty, "Should report at least one error")
    }

    @Test("Validate JSON with trailing comma is invalid")
    func validateTrailingComma() async throws {
        let json = #"{"name": "John", "age": 30,}"#
        let result = JSONValidator.validate(json)
        #expect(!result.isValid, "Trailing comma should make JSON invalid")
    }

    @Test("Validate JSON with unquoted/undefined value is invalid")
    func validateUndefinedValue() async throws {
        let json = #"{"name": "John", "age": undefined}"#
        let result = JSONValidator.validate(json)
        #expect(!result.isValid, "Undefined literal should make JSON invalid")
    }

    @Test("Validate empty JSON")
    func validateEmptyJSON() async throws {
        let result = JSONValidator.validate("")
        #expect(!result.isValid, "Empty JSON should not be valid")
        #expect(result.errors.count == 1, "Should have exactly one error")
        #expect(result.errors.first?.type == .emptyInput, "Error should be emptyInput type")
    }

    @Test("Validate whitespace-only JSON is treated as empty")
    func validateWhitespaceOnlyJSON() async throws {
        let result = JSONValidator.validate("   \n\t  ")
        #expect(!result.isValid, "Whitespace-only input should not be valid")
        #expect(result.errors.first?.type == .emptyInput, "Error should be emptyInput type")
    }

    @Test("Validate top-level primitive fragments")
    func validatePrimitiveFragments() async throws {
        for fragment in [#""just a string""#, "42", "true", "null", "-3.14"] {
            let result = JSONValidator.validate(fragment)
            #expect(result.isValid, "Top-level primitive '\(fragment)' should be valid JSON")
        }
    }

    @Test("Format JSON string produces valid, prettified output")
    func formatObjectJSON() async throws {
        let unformatted = #"{"name":"John","age":30}"#
        let formatted = try #require(JSONValidator.formatJSON(unformatted), "Should format successfully")
        #expect(formatted.contains("\n"), "Formatted JSON should have newlines")
        // Round-trip: formatted output must itself be valid JSON.
        #expect(JSONValidator.validate(formatted).isValid, "Formatted output should remain valid JSON")
    }

    @Test("Format JSON handles top-level primitive fragments (regression)")
    func formatPrimitiveFragment() async throws {
        // Regression test: formatJSON previously returned nil for valid fragments
        // because it didn't pass `.fragmentsAllowed` to JSONSerialization.
        let formattedString = JSONValidator.formatJSON(#""hello""#)
        #expect(formattedString != nil, "Formatting a bare string fragment should not fail")

        let formattedNumber = JSONValidator.formatJSON("42")
        #expect(formattedNumber != nil, "Formatting a bare number fragment should not fail")
    }

    @Test("Format invalid JSON returns nil")
    func formatInvalidJSONReturnsNil() async throws {
        let formatted = JSONValidator.formatJSON(SampleJSONData.invalid)
        #expect(formatted == nil, "Formatting invalid JSON should return nil")
    }
}

@Suite("JSON Parser Tests")
struct JSONParserTests {

    @Test("Parse simple JSON to nodes")
    func parseSimpleJSON() async throws {
        let nodes = JSONParser.parse(SampleJSONData.simple)
        let rootNode = try #require(nodes?.first, "Should have root node")

        #expect(rootNode.children.count > 0, "Should have child nodes")
        #expect(rootNode.value.displayType == "Object", "Root should be an object")
    }

    @Test("Parse JSON with arrays")
    func parseJSONWithArrays() async throws {
        let nodes = JSONParser.parse(SampleJSONData.withArray)
        let rootNode = try #require(nodes?.first, "Should have root node")

        #expect(rootNode.children.count > 0, "Should have child nodes")

        let usersNode = rootNode.children.first { $0.key == "users" }
        let unwrappedUsersNode = try #require(usersNode, "Should have users array")

        #expect(unwrappedUsersNode.value.displayType == "Array", "Users should be an array")
        #expect(unwrappedUsersNode.children.count == 3, "Users array should have 3 items")
    }

    @Test("Parse nested JSON")
    func parseNestedJSON() async throws {
        let nodes = JSONParser.parse(SampleJSONData.nested)
        let rootNode = try #require(nodes?.first, "Should have root node")

        #expect(rootNode.children.count > 0, "Should have child nodes")

        let userNode = rootNode.children.first { $0.key == "user" }
        let unwrappedUserNode = try #require(userNode, "Should have user object")

        #expect(unwrappedUserNode.children.count > 0, "User should have properties")
    }

    @Test("Parse returns nil for invalid JSON")
    func parseInvalidJSONReturnsNil() async throws {
        #expect(JSONParser.parse(SampleJSONData.invalid) == nil, "Invalid JSON should not parse")
        #expect(JSONParser.parseToRoot(SampleJSONData.invalid) == nil, "Invalid JSON should not produce a root node")
    }

    @Test("Parse empty object and empty array")
    func parseEmptyContainers() async throws {
        let emptyObjectRoot = try #require(JSONParser.parseToRoot("{}"), "Empty object should parse")
        #expect(emptyObjectRoot.value.displayType == "Object")
        #expect(emptyObjectRoot.children.isEmpty, "Empty object should have no children")
        #expect(emptyObjectRoot.isExpandable == false, "Empty object should not be expandable")
        #expect(emptyObjectRoot.countDisplay == "0 properties", "Empty object should still show a 0 count (regression)")

        let emptyArrayRoot = try #require(JSONParser.parseToRoot("[]"), "Empty array should parse")
        #expect(emptyArrayRoot.value.displayType == "Array")
        #expect(emptyArrayRoot.children.isEmpty, "Empty array should have no children")
        #expect(emptyArrayRoot.countDisplay == "0 items", "Empty array should still show a 0 count (regression)")
    }

    @Test("Parse top-level primitive fragments")
    func parsePrimitiveFragments() async throws {
        let stringRoot = try #require(JSONParser.parseToRoot(#""hello""#))
        #expect(stringRoot.displayValue == #""hello""#)

        let numberRoot = try #require(JSONParser.parseToRoot("42"))
        if case .number(let value) = numberRoot.value {
            #expect(value == 42)
        } else {
            Issue.record("Expected a number value")
        }

        let boolRoot = try #require(JSONParser.parseToRoot("true"))
        if case .bool(let value) = boolRoot.value {
            #expect(value == true)
        } else {
            Issue.record("Expected a boolean value")
        }

        let nullRoot = try #require(JSONParser.parseToRoot("null"))
        if case .null = nullRoot.value {
            // expected
        } else {
            Issue.record("Expected a null value")
        }
    }

    @Test("Parse null values within an object")
    func parseNullValue() async throws {
        let root = try #require(JSONParser.parseToRoot(#"{"middleName": null}"#))
        let node = try #require(root.children.first { $0.key == "middleName" })
        #expect(node.displayValue == "null")
    }

    @Test("Parse special characters, escaped sequences, and unicode")
    func parseSpecialCharacters() async throws {
        let json = #"""
        {
          "quote": "She said \"hello\"",
          "backslash": "C:\\path\\to\\file",
          "newline": "line1\nline2",
          "unicode": "caf\u00e9 \ud83d\ude00",
          "empty": ""
        }
        """#

        let root = try #require(JSONParser.parseToRoot(json))

        let quoteNode = try #require(root.children.first { $0.key == "quote" })
        #expect(quoteNode.displayValue == #""She said \"hello\"""#)

        let backslashNode = try #require(root.children.first { $0.key == "backslash" })
        if case .string(let value) = backslashNode.value {
            #expect(value == #"C:\path\to\file"#)
        } else {
            Issue.record("Expected a string value")
        }

        let newlineNode = try #require(root.children.first { $0.key == "newline" })
        if case .string(let value) = newlineNode.value {
            #expect(value.contains("\n"), "Escaped newline should decode to an actual newline")
        } else {
            Issue.record("Expected a string value")
        }

        let unicodeNode = try #require(root.children.first { $0.key == "unicode" })
        if case .string(let value) = unicodeNode.value {
            #expect(value.contains("café"), "Unicode escape should decode correctly")
            #expect(value.contains("😀"), "Surrogate pair emoji escape should decode correctly")
        } else {
            Issue.record("Expected a string value")
        }

        let emptyNode = try #require(root.children.first { $0.key == "empty" })
        #expect(emptyNode.displayValue == #""""#, "Empty string should still render quoted")
    }

    @Test("Object children are sorted alphabetically by key")
    func objectChildrenAreSorted() async throws {
        let root = try #require(JSONParser.parseToRoot(#"{"zebra": 1, "apple": 2, "mango": 3}"#))
        let keys = root.children.compactMap(\.key)
        #expect(keys == ["apple", "mango", "zebra"], "Object keys should be sorted alphabetically")
    }

    @Test("Array children preserve original order and index-based keys")
    func arrayChildrenPreserveOrder() async throws {
        let root = try #require(JSONParser.parseToRoot(#"["c", "a", "b"]"#))
        let keys = root.children.map(\.key)
        #expect(keys == ["[0]", "[1]", "[2]"], "Array children should retain original order")

        if case .string(let value) = root.children[0].value {
            #expect(value == "c", "First array element should not be re-sorted")
        } else {
            Issue.record("Expected a string value")
        }
    }

    // MARK: - Regression: double-nesting bug

    @Test("No phantom duplicate node is created for nested objects (regression)")
    func noPhantomNodeForNestedObjects() async throws {
        // Previously, parsing produced an extra "phantom" node with the same key one level
        // below every non-primitive value, requiring an extra expand to reach real children.
        let root = try #require(JSONParser.parseToRoot(SampleJSONData.nested))
        let userNode = try #require(root.children.first { $0.key == "user" })

        // The direct children of "user" must be its real properties (id, name, email, ...),
        // not a single child also named "user".
        #expect(userNode.children.contains { $0.key == "id" }, "user node should directly contain 'id'")
        #expect(userNode.children.contains { $0.key == "name" }, "user node should directly contain 'name'")
        #expect(!(userNode.children.count == 1 && userNode.children.first?.key == "user"),
                "user node should not contain a single phantom duplicate of itself")
    }

    @Test("No phantom duplicate node is created for nested arrays (regression)")
    func noPhantomNodeForNestedArrays() async throws {
        let root = try #require(JSONParser.parseToRoot(SampleJSONData.withArray))
        let usersNode = try #require(root.children.first { $0.key == "users" })
        let firstUser = try #require(usersNode.children.first)

        // firstUser's direct children should be its real properties (id, name), not a
        // single phantom child re-labeled "[0]".
        #expect(firstUser.children.contains { $0.key == "id" }, "array element should directly contain 'id'")
        #expect(!(firstUser.children.count == 1 && firstUser.children.first?.key == "[0]"),
                "array element should not contain a single phantom duplicate of itself")
    }

    @Test("Leaf/primitive nodes have no children and are not expandable (regression)")
    func leafNodesHaveNoChildren() async throws {
        // Previously every primitive leaf (string/number/bool/null) ended up with exactly
        // one phantom child (a duplicate of itself), making it incorrectly "expandable".
        let root = try #require(JSONParser.parseToRoot(SampleJSONData.simple))
        for child in root.children {
            #expect(child.children.isEmpty, "'\(child.key ?? "?")' is a primitive and should have no children")
            #expect(child.isExpandable == false, "'\(child.key ?? "?")' should not be expandable")
        }
    }

    // MARK: - Regression: boolean vs. number misclassification

    @Test("Booleans parse as .bool, not .number (regression)")
    func booleansParseCorrectly() async throws {
        // Previously `as? Double` was checked before `as? Bool`, so JSON `true`/`false`
        // were silently converted to 1.0/0.0.
        let root = try #require(JSONParser.parseToRoot(SampleJSONData.complex))
        let activeNode = try #require(root.children.first { $0.key == "active" })

        guard case .bool(let value) = activeNode.value else {
            Issue.record("Expected 'active' to parse as .bool, got \(activeNode.value.displayType)")
            return
        }
        #expect(value == false, "'active' in the complex sample should be false")
        #expect(activeNode.displayValue == "false", "Boolean should display as 'true'/'false', not a number")

        let publicNode = try #require(root.children.first { $0.key == "public" })
        guard case .bool = publicNode.value else {
            Issue.record("Expected 'public' to parse as .bool, got \(publicNode.value.displayType)")
            return
        }
    }

    @Test("Zero and one number values remain numbers, not booleans (regression)")
    func numericZeroAndOneAreNotBooleans() async throws {
        // Guards against an overly aggressive fix: 0/1 as JSON numbers must stay numbers.
        let root = try #require(JSONParser.parseToRoot(#"{"count": 0, "total": 1}"#))

        let countNode = try #require(root.children.first { $0.key == "count" })
        guard case .number(let countValue) = countNode.value else {
            Issue.record("Expected 'count' to remain a .number")
            return
        }
        #expect(countValue == 0)

        let totalNode = try #require(root.children.first { $0.key == "total" })
        guard case .number(let totalValue) = totalNode.value else {
            Issue.record("Expected 'total' to remain a .number")
            return
        }
        #expect(totalValue == 1)
    }

    // MARK: - Large JSON

    @Test("Parses a very large, deeply-nested JSON document without crashing")
    func parseLargeJSON() async throws {
        let itemCount = 5_000
        let items = (0..<itemCount).map { i in
            #"{"id": \#(i), "name": "Item \#(i)", "active": \#(i % 2 == 0), "tags": ["a", "b", "c"]}"#
        }.joined(separator: ",")
        let largeJSON = "{\"items\": [\(items)], \"count\": \(itemCount)}"

        let clock = ContinuousClock()
        let start = clock.now
        let root = try #require(JSONParser.parseToRoot(largeJSON), "Large JSON should parse successfully")
        let elapsed = clock.now - start

        let itemsNode = try #require(root.children.first { $0.key == "items" })
        #expect(itemsNode.children.count == itemCount, "All \(itemCount) items should be parsed")

        // Soft performance guard: parsing shouldn't take an unreasonable amount of time.
        // Generous bound to avoid flakiness across CI hardware.
        #expect(elapsed < .seconds(10), "Parsing \(itemCount) items took too long: \(elapsed)")
    }
}

@Suite("JSONNode Tests")
struct JSONNodeTests {

    @Test("JSON node display properties for each value type")
    func jsonNodeProperties() async throws {
        let stringNode = JSONNode(key: "name", value: .string("John"))
        #expect(stringNode.displayName == "name", "Display name should match key")
        #expect(stringNode.displayValue == #""John""#, "String value should be quoted")
        #expect(stringNode.iconName == "textformat.abc", "String should have text icon")

        let numberNode = JSONNode(key: "age", value: .number(30))
        #expect(numberNode.displayValue == "30.0", "Number should display correctly")

        let boolNode = JSONNode(key: "active", value: .bool(true))
        #expect(boolNode.displayValue == "true", "Boolean should display correctly")

        let nullNode = JSONNode(key: "value", value: .null)
        #expect(nullNode.displayValue == "null", "Null should display correctly")

        let objectNode = JSONNode(key: "user", value: .object([:]))
        #expect(objectNode.displayValue == nil, "Objects should not have a direct display value")

        let arrayNode = JSONNode(key: "items", value: .array([]))
        #expect(arrayNode.displayValue == nil, "Arrays should not have a direct display value")
    }

    @Test("displayName falls back to type name when key is nil")
    func displayNameFallsBackToType() async throws {
        let node = JSONNode(key: nil, value: .object([:]))
        #expect(node.displayName == "Object", "Root nodes without a key should show their type")
    }

    @Test("isExpandable reflects presence of children")
    func isExpandableReflectsChildren() async throws {
        let leaf = JSONNode(key: "leaf", value: .string("value"))
        #expect(leaf.isExpandable == false)

        let parent = JSONNode(key: "parent", value: .object(["child": "value"]), children: [
            JSONNode(key: "child", value: .string("value"))
        ])
        #expect(parent.isExpandable == true)
    }

    @Test("countDisplay reports 0 for empty containers (regression)")
    func countDisplayForEmptyContainers() async throws {
        let emptyObject = JSONNode(key: "obj", value: .object([:]), children: [])
        #expect(emptyObject.countDisplay == "0 properties")

        let emptyArray = JSONNode(key: "arr", value: .array([]), children: [])
        #expect(emptyArray.countDisplay == "0 items")

        let oneProperty = JSONNode(key: "obj2", value: .object(["a": 1]), children: [
            JSONNode(key: "a", value: .number(1))
        ])
        #expect(oneProperty.countDisplay == "1 property", "Singular form should be used for exactly one property")
    }
}

// MARK: - Edge Case Matrix additions (section 6 of TEST_PLAN.swift)

@Suite("JSON Edge Case Tests")
struct JSONEdgeCaseTests {

    @Test("Duplicate keys in an object do not crash (last value wins)")
    func duplicateKeysDoNotCrash() async throws {
        let json = #"{"a": 1, "a": 2}"#
        let result = JSONValidator.validate(json)
        #expect(result.isValid, "JSONSerialization allows duplicate keys; should still be valid")

        let root = JSONParser.parseToRoot(json)
        #expect(root != nil, "Should parse without crashing")
        #expect(root?.children.count == 1, "Dictionary collapses duplicate keys to a single entry")
    }

    @Test("Negative and exponent numbers are never misread as booleans")
    func negativeAndExponentNumbers() async throws {
        let json = #"{"neg": -5, "exp": 1.5e3, "negExp": -2.5e-2}"#
        let root = JSONParser.parseToRoot(json)
        #expect(root != nil)

        let neg = root?.children.first { $0.key == "neg" }
        let exp = root?.children.first { $0.key == "exp" }
        let negExp = root?.children.first { $0.key == "negExp" }

        if case .number(let value)? = neg?.value {
            #expect(value == -5)
        } else {
            Issue.record("Expected 'neg' to parse as .number")
        }

        if case .number(let value)? = exp?.value {
            #expect(value == 1500)
        } else {
            Issue.record("Expected 'exp' to parse as .number")
        }

        if case .number(let value)? = negExp?.value {
            #expect(value == -0.025)
        } else {
            Issue.record("Expected 'negExp' to parse as .number")
        }
    }

    @Test("Extremely long string value parses without truncation")
    func extremelyLongStringValue() async throws {
        let longValue = String(repeating: "a", count: 50_000)
        let json = #"{"big": "\#(longValue)"}"#

        let root = JSONParser.parseToRoot(json)
        let bigNode = root?.children.first { $0.key == "big" }

        if case .string(let value)? = bigNode?.value {
            #expect(value.count == 50_000, "Long string should not be truncated during parsing")
        } else {
            Issue.record("Expected 'big' to parse as .string")
        }
    }

    @Test("Pasting plain, non-JSON prose is reported as invalid, not a crash")
    func nonJSONProseIsInvalid() async throws {
        let prose = "This is just some plain English text, not JSON at all."
        let result = JSONValidator.validate(prose)
        #expect(!result.isValid, "Plain prose should fail validation")
        #expect(!result.errors.isEmpty)
        #expect(JSONParser.parseToRoot(prose) == nil, "Parser should return nil, not crash")
    }
}

// MARK: - JSONStatistics Tests (TEST_PLAN.swift UI-03)

@Suite("JSON Statistics Tests")
struct JSONStatisticsTests {

    @Test("Statistics counts match a known, hand-built tree")
    func statisticsMatchKnownTree() async throws {
        // { "name": "John", "age": 30, "active": true, "meta": null, "tags": ["a", "b"] }
        let root = JSONNode(key: nil, value: .object([:]), children: [
            JSONNode(key: "name", value: .string("John")),
            JSONNode(key: "age", value: .number(30)),
            JSONNode(key: "active", value: .bool(true)),
            JSONNode(key: "meta", value: .null),
            JSONNode(key: "tags", value: .array(["a", "b"]), children: [
                JSONNode(key: "[0]", value: .string("a")),
                JSONNode(key: "[1]", value: .string("b"))
            ])
        ])

        let stats = JSONStatistics.calculate(from: root)

        #expect(stats.objectCount == 1, "Only the root is an object")
        #expect(stats.arrayCount == 1, "'tags' is the only array")
        #expect(stats.stringCount == 3, "'name', and the two array string elements")
        #expect(stats.numberCount == 1, "'age'")
        #expect(stats.boolCount == 1, "'active'")
        #expect(stats.nullCount == 1, "'meta'")
        #expect(stats.totalNodes == 8, "root + name + age + active + meta + tags + 2 array elements")
        #expect(stats.maxDepth == 2, "Array elements are at depth 2 (root -> tags -> element)")
    }

    @Test("Statistics for a nil root return all zeros")
    func statisticsForNilRoot() async throws {
        let stats = JSONStatistics.calculate(from: nil)
        #expect(stats.totalNodes == 0)
        #expect(stats.objectCount == 0)
        #expect(stats.arrayCount == 0)
    }

    @Test("Statistics from a real parsed sample match a manual recount")
    func statisticsFromParsedSample() async throws {
        let root = JSONParser.parseToRoot(SampleJSONData.nested)
        let stats = JSONStatistics.calculate(from: root)

        // Sanity checks rather than brittle exact counts tied to sample content:
        #expect(stats.totalNodes > 0)
        #expect(stats.totalNodes == 1 + countAllChildren(of: root))
    }

    private func countAllChildren(of node: JSONNode?) -> Int {
        guard let node else { return 0 }
        return node.children.reduce(0) { $0 + 1 + countAllChildren(of: $1) }
    }
}

// MARK: - JSONTreeSearchEngine Tests (TEST_PLAN.swift UI-01, UI-02)

@Suite("JSONTreeSearchEngine Tests")
struct JSONTreeSearchEngineTests {

    private func makeTree() -> JSONNode {
        // { "user": { "firstName": "John", "lastName": "Doe" }, "tags": ["admin", "editor"] }
        let firstName = JSONNode(key: "firstName", value: .string("John"))
        let lastName = JSONNode(key: "lastName", value: .string("Doe"))
        let user = JSONNode(key: "user", value: .object([:]), children: [firstName, lastName])
        let tag0 = JSONNode(key: "[0]", value: .string("admin"))
        let tag1 = JSONNode(key: "[1]", value: .string("editor"))
        let tags = JSONNode(key: "tags", value: .array([]), children: [tag0, tag1])
        return JSONNode(key: nil, value: .object([:]), children: [user, tags])
    }

    @Test("searchNodes matches keys case-insensitively at any depth")
    func searchMatchesKeysCaseInsensitively() async throws {
        let root = makeTree()
        let results = JSONTreeSearchEngine.searchNodes(in: root, query: "FIRSTNAME")
        #expect(results.count == 1)
        #expect(results.first?.key == "firstName")
    }

    @Test("searchNodes matches values as well as keys")
    func searchMatchesValues() async throws {
        let root = makeTree()
        let results = JSONTreeSearchEngine.searchNodes(in: root, query: "admin")
        #expect(results.contains { $0.key == "[0]" })
    }

    @Test("searchNodes returns multiple matches across different branches")
    func searchReturnsMultipleMatches() async throws {
        let root = makeTree()
        // "e" appears in "lastName" (key, via 'e' in "Name")... use a query guaranteed to hit two branches instead.
        let results = JSONTreeSearchEngine.searchNodes(in: root, query: "name")
        let matchedKeys = Set(results.compactMap(\.key))
        #expect(matchedKeys.contains("firstName"))
        #expect(matchedKeys.contains("lastName"))
    }

    @Test("searchNodes with an empty query returns no results")
    func searchWithEmptyQueryReturnsEmpty() async throws {
        let root = makeTree()
        #expect(JSONTreeSearchEngine.searchNodes(in: root, query: "").isEmpty)
    }

    @Test("searchNodes with no matches returns an empty array, not nil")
    func searchWithNoMatchesReturnsEmpty() async throws {
        let root = makeTree()
        #expect(JSONTreeSearchEngine.searchNodes(in: root, query: "zzz-no-match-zzz").isEmpty)
    }

    @Test("collectAllNodeIds returns the root plus every descendant exactly once (Expand All)")
    func collectAllNodeIdsCoversWholeTree() async throws {
        let root = makeTree()
        let ids = JSONTreeSearchEngine.collectAllNodeIds(from: root)

        // root + user + firstName + lastName + tags + tag0 + tag1 = 7 nodes
        #expect(ids.count == 7)
        #expect(ids.contains(root.id))
        for child in root.children {
            #expect(ids.contains(child.id))
            for grandchild in child.children {
                #expect(ids.contains(grandchild.id))
            }
        }
    }

    @Test("ancestorIdsToExpand returns only the ancestors, not the target itself (search result jump)")
    func ancestorIdsToExpandReturnsAncestorsOnly() async throws {
        let root = makeTree()
        let user = root.children[0]
        let firstName = user.children[0]

        let ancestors = JSONTreeSearchEngine.ancestorIdsToExpand(toReveal: firstName.id, in: root)

        #expect(ancestors.contains(root.id), "Root must be expanded to reveal a great-grandchild")
        #expect(ancestors.contains(user.id), "Direct parent must be expanded")
        #expect(!ancestors.contains(firstName.id), "The target node itself should not be in the ancestor set")
    }

    @Test("ancestorIdsToExpand for an unknown id returns an empty set")
    func ancestorIdsToExpandForUnknownIdReturnsEmpty() async throws {
        let root = makeTree()
        #expect(JSONTreeSearchEngine.ancestorIdsToExpand(toReveal: UUID(), in: root).isEmpty)
    }
}

// MARK: - JSONEditorViewModel Tests (TEST_PLAN.swift VM-01..VM-08)

@MainActor
@Suite("JSONEditorViewModel Tests")
struct JSONEditorViewModelTests {

    @Test("Typing schedules debounced validation (rootNode updates after the delay, not immediately)")
    func typingTriggersDebouncedValidation() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = SampleJSONData.simple

        // Immediately after assignment, validation hasn't run yet (debounced ~300ms).
        #expect(vm.rootNode == nil, "Validation should not have completed synchronously")

        try await Task.sleep(for: .milliseconds(500))

        #expect(vm.rootNode != nil, "Validation should complete after the debounce window")
        #expect(vm.hasErrors == false)
    }

    @Test("validateNow() bypasses the debounce and validates synchronously")
    func validateNowBypassesDebounce() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = SampleJSONData.simple
        vm.validateNow()

        #expect(vm.rootNode != nil, "validateNow should populate rootNode immediately")
        #expect(vm.hasErrors == false)
    }

    @Test("loadSample sets text and can be validated immediately via validateNow")
    func loadSampleLoadsKnownGoodSample() async throws {
        let vm = JSONEditorViewModel()
        vm.loadSample(SampleJSONData.simple)
        vm.validateNow()

        #expect(vm.jsonText == SampleJSONData.simple)
        #expect(vm.rootNode != nil)
        #expect(vm.hasErrors == false)
    }

    @Test("formatJSON() prettifies valid, minified text")
    func formatJSONOnValidText() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = #"{"a":1,"b":2}"#
        vm.formatJSON()

        #expect(vm.jsonText.contains("\n"), "Formatted JSON should be multi-line")
        #expect(vm.jsonText != #"{"a":1,"b":2}"#)
    }

    @Test("formatJSON() on invalid text is a no-op")
    func formatJSONOnInvalidTextIsNoOp() async throws {
        let vm = JSONEditorViewModel()
        let invalidText = "{invalid"
        vm.jsonText = invalidText
        vm.formatJSON()

        #expect(vm.jsonText == invalidText, "Invalid text should be left unchanged")
    }

    @Test("clear() resets all editor state")
    func clearResetsAllState() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = SampleJSONData.simple
        vm.validateNow()
        #expect(vm.rootNode != nil)

        vm.clear()

        #expect(vm.jsonText == "")
        #expect(vm.rootNode == nil)
        #expect(vm.hasErrors == false)
        #expect(vm.isValidating == false)
    }

    @Test("pasteFromClipboard() with an empty clipboard is a no-op")
    func pasteFromEmptyClipboardIsNoOp() async throws {
        ClipboardHelper.write("")
        let vm = JSONEditorViewModel()
        vm.jsonText = "unchanged"

        vm.pasteFromClipboard()

        #expect(vm.jsonText == "unchanged", "Empty clipboard contents should not overwrite editor text")
    }

    @Test("copyToClipboard() round-trips the current editor text")
    func copyToClipboardRoundTrips() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = SampleJSONData.simple

        vm.copyToClipboard()

        #expect(ClipboardHelper.readString() == SampleJSONData.simple)
    }

    @Test("exportData() produces re-parseable, valid UTF-8 JSON")
    func exportDataProducesValidJSON() async throws {
        let vm = JSONEditorViewModel()
        vm.jsonText = #"{"a":1,"b":[1,2,3]}"#

        let data = vm.exportData()
        #expect(data != nil)

        let string = try #require(String(data: data!, encoding: .utf8))
        #expect(JSONValidator.validate(string).isValid)
    }
}

// MARK: - JSONExportDocument Tests (TEST_PLAN.swift VM-09)

@Suite("JSONExportDocument Tests")
struct JSONExportDocumentTests {

    @Test("Wraps arbitrary JSON data without modification")
    func wrapsDataUnmodified() async throws {
        let json = #"{"a":1}"#
        let data = try #require(json.data(using: .utf8))

        let document = JSONExportDocument(data: data)
        #expect(document.data == data)
    }

    @Test("Declares JSON as both a readable and writable content type")
    func declaresJSONContentType() async throws {
        #expect(JSONExportDocument.readableContentTypes.contains(.json))
        #expect(JSONExportDocument.writableContentTypes.contains(.json))
    }
}

// MARK: - ClipboardHelper Tests (TEST_PLAN.swift VM-10)

@Suite("ClipboardHelper Tests")
struct ClipboardHelperTests {

    @Test("write/readString round-trips a value through the system pasteboard")
    func writeAndReadRoundTrip() async throws {
        let unique = "ValidateJson-ClipboardTest-\(UUID().uuidString)"
        ClipboardHelper.write(unique)

        #expect(ClipboardHelper.readString() == unique)
    }

    @Test("Overwriting the clipboard replaces the previous value")
    func overwriteReplacesPreviousValue() async throws {
        ClipboardHelper.write("first-value")
        ClipboardHelper.write("second-value")

        #expect(ClipboardHelper.readString() == "second-value")
    }
}

import Foundation
import UniformTypeIdentifiers

