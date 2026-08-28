//
//  JSONTreeSearchEngine.swift
//  ValidateJson
//
//  Pure, testable tree traversal helpers extracted from EnhancedJSONTreeView
//  so search / expand-all / collapse-all / "expand path to node" logic can be
//  unit tested without a running SwiftUI view hierarchy (TEST_PLAN.swift
//  UI-01 and UI-02).
//

import Foundation

enum JSONTreeSearchEngine {

    /// Returns every node (at any depth) whose key or display value contains
    /// `query` (case-insensitive). `query` should already be trimmed; an
    /// empty query returns an empty result set (mirrors the view's behavior
    /// of only searching once the user has typed something).
    static func searchNodes(in node: JSONNode, query: String) -> [JSONNode] {
        guard !query.isEmpty else { return [] }
        let lowercasedQuery = query.lowercased()
        return search(in: node, lowercasedQuery: lowercasedQuery)
    }

    private static func search(in node: JSONNode, lowercasedQuery: String) -> [JSONNode] {
        var results: [JSONNode] = []

        if let key = node.key, key.lowercased().contains(lowercasedQuery) {
            results.append(node)
        }

        if let value = node.displayValue, value.lowercased().contains(lowercasedQuery) {
            results.append(node)
        }

        for child in node.children {
            results.append(contentsOf: search(in: child, lowercasedQuery: lowercasedQuery))
        }

        return results
    }

    /// All node ids in the subtree rooted at `node`, used to implement "Expand All".
    static func collectAllNodeIds(from node: JSONNode) -> Set<UUID> {
        var ids: Set<UUID> = [node.id]
        for child in node.children {
            ids.formUnion(collectAllNodeIds(from: child))
        }
        return ids
    }

    /// Returns the ids of every ancestor node that must be expanded in order
    /// to reveal `targetId` (used when jumping to a search result). The
    /// target node itself is not included since it doesn't need to be
    /// "expanded" to be visible — only its ancestors do.
    static func ancestorIdsToExpand(toReveal targetId: UUID, in node: JSONNode) -> Set<UUID> {
        var ancestors: Set<UUID> = []
        _ = containsTarget(targetId, in: node, ancestors: &ancestors)
        return ancestors
    }

    @discardableResult
    private static func containsTarget(_ targetId: UUID, in node: JSONNode, ancestors: inout Set<UUID>) -> Bool {
        if node.id == targetId {
            return true
        }

        for child in node.children {
            if containsTarget(targetId, in: child, ancestors: &ancestors) {
                ancestors.insert(node.id)
                return true
            }
        }

        return false
    }
}
