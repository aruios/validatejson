//
//  EnhancedJSONTreeView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 3 ENHANCED: Advanced tree view with search, stats, and more

import SwiftUI

/// Enhanced tree view with search, statistics, and context menus
struct EnhancedJSONTreeView: View {
    let rootNode: JSONNode?
    @State private var expandedNodes: Set<UUID> = []
    @State private var searchText = ""
    @State private var searchResults: [JSONNode] = []
    @State private var highlightedNodeId: UUID?
    @State private var showStatistics = true
    @State private var searchTask: Task<Void, Never>?
    
    private var statistics: JSONStatistics {
        JSONStatistics.calculate(from: rootNode)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            treeToolbar
            
            Divider()
            
            // Search
            if rootNode != nil {
                TreeSearchView(
                    searchText: $searchText,
                    searchResults: $searchResults,
                    onResultSelected: handleSearchResultSelected
                )
                .onChange(of: searchText) { oldValue, newValue in
                    scheduleSearch(query: newValue)
                }
                
                Divider()
            }
            
            // Statistics
            if showStatistics, rootNode != nil {
                TreeStatisticsView(statistics: statistics)
                Divider()
            }
            
            // Tree Content
            if let root = rootNode {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        EnhancedTreeNodeView(
                            node: root,
                            level: 0,
                            expandedNodes: $expandedNodes,
                            highlightedNodeId: $highlightedNodeId
                        )
                    }
                    .padding(8)
                }
            } else {
                emptyState
            }
        }
        .onChange(of: rootNode) { oldValue, newValue in
            // Auto-expand root and first level when new JSON is loaded
            if let root = newValue {
                expandedNodes.insert(root.id)
                expandedNodes.formUnion(root.children.map(\.id))
            }
            // Clear search when JSON changes
            searchTask?.cancel()
            searchText = ""
            searchResults = []
            highlightedNodeId = nil
        }
    }
    
    // MARK: - Toolbar
    
    private var treeToolbar: some View {
        HStack {
            Text("Tree Structure")
                .font(.headline)
            
            Spacer()
            
            if rootNode != nil {
                Button {
                    withAnimation {
                        showStatistics.toggle()
                    }
                } label: {
                    Label("Statistics", systemImage: showStatistics ? "chart.bar.fill" : "chart.bar")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .help("Toggle statistics (⇧⌘S)")
                .accessibilityIdentifier("tree.toolbar.statistics")
                
                Divider()
                    .frame(height: 16)
                
                Button {
                    expandAll()
                } label: {
                    Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .help("Expand all nodes (⌥⌘→)")
                .accessibilityIdentifier("tree.toolbar.expandAll")
                
                Button {
                    collapseAll()
                } label: {
                    Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .help("Collapse all nodes (⌥⌘←)")
                .accessibilityIdentifier("tree.toolbar.collapseAll")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No JSON to display")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("Enter valid JSON in the editor to see the tree structure")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Search

    /// Debounces search so large trees aren't re-scanned on every keystroke (Phase 5 perf).
    private func scheduleSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            performSearch(query: query)
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty, let root = rootNode else {
            searchResults = []
            return
        }

        searchResults = JSONTreeSearchEngine.searchNodes(in: root, query: query)
    }
    
    private func handleSearchResultSelected(_ nodeId: UUID) {
        // Highlight the node
        highlightedNodeId = nodeId
        
        // Expand path to node
        if let root = rootNode {
            expandedNodes.formUnion(JSONTreeSearchEngine.ancestorIdsToExpand(toReveal: nodeId, in: root))
        }
        
        // Clear highlight after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                highlightedNodeId = nil
            }
        }
    }
    
    // MARK: - Actions
    
    private func expandAll() {
        guard let root = rootNode else { return }
        withAnimation {
            expandedNodes = JSONTreeSearchEngine.collectAllNodeIds(from: root)
        }
    }
    
    private func collapseAll() {
        withAnimation {
            expandedNodes.removeAll()
        }
    }
}

// MARK: - Enhanced Tree Node View

struct EnhancedTreeNodeView: View {
    let node: JSONNode
    let level: Int
    @Binding var expandedNodes: Set<UUID>
    @Binding var highlightedNodeId: UUID?
    
    private let indentWidth: CGFloat = 20
    private var isExpanded: Bool {
        expandedNodes.contains(node.id)
    }
    private var isHighlighted: Bool {
        highlightedNodeId == node.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node row
            nodeRow
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHighlighted ? Color.blue.opacity(0.2) : Color.clear)
                        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                )
                .contextMenu {
                    TreeNodeContextMenu(node: node)
                }
                .accessibilityIdentifier("tree.node.\(node.displayName)")
            
            // Children (if expanded)
            if isExpanded && node.isExpandable {
                ForEach(node.children) { child in
                    EnhancedTreeNodeView(
                        node: child,
                        level: level + 1,
                        expandedNodes: $expandedNodes,
                        highlightedNodeId: $highlightedNodeId
                    )
                }
            }
        }
    }
    
    // MARK: - Node Row
    
    private var nodeRow: some View {
        HStack(spacing: 6) {
            // Indentation
            Color.clear
                .frame(width: CGFloat(level) * indentWidth)
            
            // Expand/Collapse Button
            if node.isExpandable {
                Button {
                    toggleExpansion()
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 12, height: 12)
            }
            
            // Icon
            Image(systemName: node.iconName)
                .foregroundStyle(iconColor)
                .font(.caption)
                .frame(width: 16)
            
            // Key/Name
            Text(node.displayName)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
            
            // Value or Count
            if let value = node.displayValue {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
            } else if let count = node.countDisplay {
                Text(count)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            if node.isExpandable {
                toggleExpansion()
            }
        }
    }
    
    // MARK: - Styling
    
    private var iconColor: Color {
        switch node.value {
        case .object: return .blue
        case .array: return .purple
        case .string: return .green
        case .number: return .orange
        case .bool: return .pink
        case .null: return .secondary
        }
    }
    
    private var valueColor: Color {
        switch node.value {
        case .string: return .green
        case .number: return .orange
        case .bool: return .pink
        case .null: return .secondary
        default: return .primary
        }
    }
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        withAnimation(.snappy(duration: 0.2)) {
            if isExpanded {
                expandedNodes.remove(node.id)
            } else {
                expandedNodes.insert(node.id)
            }
        }
    }
}

#Preview {
    EnhancedJSONTreeView(rootNode: JSONParser.parseToRoot(SampleJSONData.nested))
        .frame(width: 450, height: 700)
}

#Preview("Empty") {
    EnhancedJSONTreeView(rootNode: nil)
        .frame(width: 450, height: 700)
}
