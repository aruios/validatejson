//
//  JSONEditorViewModel.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class JSONEditorViewModel {
    var jsonText: String = "" {
        didSet {
            scheduleValidation()
        }
    }

    var rootNode: JSONNode?
    var parseErrors: [JSONParseError] = []
    var isValidating = false

    var hasErrors: Bool {
        !parseErrors.isEmpty
    }

    var firstErrorMessage: String? {
        parseErrors.first?.fullMessage
    }

    var characterCount: Int {
        jsonText.count
    }

    var lineCount: Int {
        jsonText.split(separator: "\n", omittingEmptySubsequences: false).count
    }

    private var validationTask: Task<Void, Never>?

    func loadSample(_ sample: String) {
        jsonText = sample
    }

    func formatJSON() {
        guard let formatted = JSONValidator.formatJSON(jsonText) else { return }
        jsonText = formatted
    }

    func clear() {
        validationTask?.cancel()
        jsonText = ""
        rootNode = nil
        parseErrors = []
        isValidating = false
    }

    func validateNow() {
        validationTask?.cancel()
        performValidationAndParsing()
    }

    /// Replaces the current text with clipboard contents, if any.
    func pasteFromClipboard() {
        guard let pasted = ClipboardHelper.readString(), !pasted.isEmpty else { return }
        jsonText = pasted
    }

    /// Copies the current editor text to the clipboard.
    func copyToClipboard() {
        guard !jsonText.isEmpty else { return }
        ClipboardHelper.write(jsonText)
    }

    /// Returns data suitable for exporting the current JSON to a file.
    /// Uses the formatted (pretty-printed) version when valid; otherwise falls back to raw text.
    func exportData() -> Data? {
        let textToExport = JSONValidator.formatJSON(jsonText) ?? jsonText
        return textToExport.data(using: .utf8)
    }

    private func scheduleValidation() {
        validationTask?.cancel()
        validationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            performValidationAndParsing()
        }
    }

    private func performValidationAndParsing() {
        isValidating = true
        defer { isValidating = false }

        let trimmed = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            rootNode = nil
            parseErrors = []
            return
        }

        switch JSONValidator.validate(jsonText) {
        case .valid:
            rootNode = JSONParser.parseToRoot(jsonText)
            parseErrors = rootNode == nil ? [
                JSONParseError(
                    type: .invalidFormat,
                    message: "Unable to render JSON tree from valid input.",
                    line: nil,
                    column: nil
                )
            ] : []
        case .invalid(let errors):
            rootNode = nil
            parseErrors = errors
        }
    }
}
