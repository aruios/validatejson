//
//  TreeStatisticsView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 3 Enhancement: Statistics about the JSON structure

import SwiftUI

/// Statistics panel showing JSON structure info
struct TreeStatisticsView: View {
    let statistics: JSONStatistics
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                }
                .padding(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color(nsColor: .controlBackgroundColor))
            
            if isExpanded {
                Divider()
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    StatItem(label: "Objects", value: "\(statistics.objectCount)", icon: "curlybraces", color: .blue)
                    StatItem(label: "Arrays", value: "\(statistics.arrayCount)", icon: "list.bullet", color: .purple)
                    StatItem(label: "Strings", value: "\(statistics.stringCount)", icon: "textformat", color: .green)
                    StatItem(label: "Numbers", value: "\(statistics.numberCount)", icon: "number", color: .orange)
                    StatItem(label: "Booleans", value: "\(statistics.boolCount)", icon: "checkmark.circle", color: .pink)
                    StatItem(label: "Nulls", value: "\(statistics.nullCount)", icon: "minus.circle", color: .secondary)
                    StatItem(label: "Max Depth", value: "\(statistics.maxDepth)", icon: "arrow.down.right", color: .cyan)
                    StatItem(label: "Total Nodes", value: "\(statistics.totalNodes)", icon: "tree", color: .indigo)
                }
                .padding(8)
            }
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
}

/// Statistics about JSON structure
struct JSONStatistics {
    var objectCount = 0
    var arrayCount = 0
    var stringCount = 0
    var numberCount = 0
    var boolCount = 0
    var nullCount = 0
    var maxDepth = 0
    var totalNodes = 0
    
    static func calculate(from node: JSONNode?, currentDepth: Int = 0) -> JSONStatistics {
        guard let node = node else { return JSONStatistics() }
        
        var stats = JSONStatistics()
        stats.totalNodes = 1
        stats.maxDepth = currentDepth
        
        switch node.value {
        case .object:
            stats.objectCount = 1
        case .array:
            stats.arrayCount = 1
        case .string:
            stats.stringCount = 1
        case .number:
            stats.numberCount = 1
        case .bool:
            stats.boolCount = 1
        case .null:
            stats.nullCount = 1
        }
        
        // Process children
        for child in node.children {
            let childStats = calculate(from: child, currentDepth: currentDepth + 1)
            stats.objectCount += childStats.objectCount
            stats.arrayCount += childStats.arrayCount
            stats.stringCount += childStats.stringCount
            stats.numberCount += childStats.numberCount
            stats.boolCount += childStats.boolCount
            stats.nullCount += childStats.nullCount
            stats.totalNodes += childStats.totalNodes
            stats.maxDepth = max(stats.maxDepth, childStats.maxDepth)
        }
        
        return stats
    }
}

#Preview {
    VStack {
        TreeStatisticsView(statistics: JSONStatistics(
            objectCount: 3,
            arrayCount: 2,
            stringCount: 15,
            numberCount: 8,
            boolCount: 4,
            nullCount: 1,
            maxDepth: 5,
            totalNodes: 33
        ))
        
        Spacer()
    }
    .frame(width: 300)
}
