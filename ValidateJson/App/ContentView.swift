//
//  ContentView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = JSONEditorViewModel()
    
    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width >= 900 {
                HSplitView {
                    JSONEditorView(viewModel: viewModel)
                        .frame(minWidth: 320, idealWidth: 460)

                    treePane
                        .frame(minWidth: 320)
                }
                .accessibilityIdentifier("layout.splitView")
            } else {
                TabView {
                    JSONEditorView(viewModel: viewModel)
                        .tabItem {
                            Label("Editor", systemImage: "pencil")
                        }

                    treePane
                        .tabItem {
                            Label("Tree", systemImage: "tree")
                        }
                }
                .accessibilityIdentifier("layout.tabView")
            }
        }
        .navigationTitle("ValidateJSON")
        .onAppear {
            if viewModel.jsonText.isEmpty {
                viewModel.loadSample(SampleJSONData.nested)
            }
        }
    }

    private var treePane: some View {
        VStack(spacing: 0) {
            if let parseErrorMessage = viewModel.firstErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(parseErrorMessage)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .accessibilityIdentifier("tree.errorBanner")
                Divider()
            }

            EnhancedJSONTreeView(rootNode: viewModel.rootNode)
        }
    }
}

#Preview {
    ContentView()
}
