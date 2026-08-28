//
//  TreeSearchView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 3 Enhancement: Search functionality for tree

import SwiftUI

/// Search bar for filtering tree nodes
struct TreeSearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [JSONNode]
    let onResultSelected: (UUID) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search keys or values...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("tree.search.field")
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .padding(8)
            
            // Search results
            if !searchText.isEmpty && !searchResults.isEmpty {
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                            .accessibilityIdentifier("tree.search.resultCount")
                        
                        ForEach(searchResults) { node in
                            Button {
                                onResultSelected(node.id)
                            } label: {
                                HStack {
                                    Image(systemName: node.iconName)
                                        .foregroundStyle(.blue)
                                    
                                    Text(node.displayName)
                                        .font(.system(.caption, design: .monospaced))
                                    
                                    if let value = node.displayValue {
                                        Text(value)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 150)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}

#Preview {
    TreeSearchView(
        searchText: .constant("name"),
        searchResults: .constant([
            JSONNode(key: "firstName", value: .string("John")),
            JSONNode(key: "lastName", value: .string("Doe"))
        ]),
        onResultSelected: { _ in }
    )
    .frame(width: 300)
}
