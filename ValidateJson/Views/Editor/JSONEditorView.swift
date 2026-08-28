//
//  JSONEditorView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct JSONEditorView: View {
    @Bindable var viewModel: JSONEditorViewModel
    @State private var showingSamplePicker = false
    @State private var showingExporter = false
    @State private var exportDocument: JSONExportDocument?

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.jsonText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .accessibilityIdentifier("editor.textView")

                if viewModel.jsonText.isEmpty {
                    Text("Paste your JSON here...")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            Divider()
            statusBar

            if viewModel.hasErrors {
                Divider()
                ValidationErrorView(errors: viewModel.parseErrors)
                    .frame(height: 120)
            }
        }
        .sheet(isPresented: $showingSamplePicker) {
            SampleJSONPicker(viewModel: viewModel)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "data.json"
        ) { _ in
            exportDocument = nil
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 12) {
            Text("JSON Editor")
                .font(.headline)

            Spacer()

            Button {
                showingSamplePicker = true
            } label: {
                Label("Load Sample", systemImage: "doc.text")
            }
            .keyboardShortcut("l", modifiers: .command)
            .help("Load sample JSON (⌘L)")
            .accessibilityIdentifier("toolbar.loadSample")

            Button {
                viewModel.pasteFromClipboard()
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
            .help("Paste JSON from clipboard, replacing current text (⇧⌘V)")
            .accessibilityIdentifier("toolbar.paste")

            Button {
                viewModel.copyToClipboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .disabled(viewModel.jsonText.isEmpty)
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .help("Copy JSON to clipboard (⇧⌘C)")
            .accessibilityIdentifier("toolbar.copy")

            Button {
                viewModel.formatJSON()
            } label: {
                Label("Format", systemImage: "text.alignleft")
            }
            .disabled(viewModel.jsonText.isEmpty || viewModel.hasErrors)
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .help("Format JSON (Pretty Print) (⇧⌘F)")
            .accessibilityIdentifier("toolbar.format")

            Button {
                exportJSON()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.jsonText.isEmpty || viewModel.hasErrors)
            .keyboardShortcut("e", modifiers: .command)
            .help("Export JSON to file (⌘E)")
            .accessibilityIdentifier("toolbar.export")

            Button {
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(viewModel.jsonText.isEmpty)
            .keyboardShortcut(.delete, modifiers: .command)
            .help("Clear editor (⌘⌫)")
            .accessibilityIdentifier("toolbar.clear")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(8)
    }

    private func exportJSON() {
        guard let data = viewModel.exportData() else { return }
        exportDocument = JSONExportDocument(data: data)
        showingExporter = true
    }

    private var statusBar: some View {
        HStack {
            HStack(spacing: 4) {
                if viewModel.isValidating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else if viewModel.jsonText.isEmpty {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                } else if viewModel.hasErrors {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("editor.statusText")
            }

            Spacer()

            Text("\(viewModel.lineCount) lines")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.secondary)

            Text("\(viewModel.characterCount) chars")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var statusText: String {
        if viewModel.isValidating {
            return "Validating..."
        }
        if viewModel.jsonText.isEmpty {
            return "No JSON"
        }
        return viewModel.hasErrors ? "Invalid JSON" : "Valid JSON"
    }
}

struct SampleJSONPicker: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: JSONEditorViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(SampleJSONData.allSamples, id: \.name) { sample in
                    Button {
                        viewModel.loadSample(sample.json)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sample.name)
                                .font(.headline)

                            Text(sample.json.prefix(100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("samplePicker.row.\(sample.name)")
                }
            }
            .navigationTitle("Load Sample JSON")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
