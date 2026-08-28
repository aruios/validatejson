//
//  JSONExportDocument.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 5: File export support via SwiftUI's fileExporter.
//

import SwiftUI
import UniformTypeIdentifiers

/// A simple file document wrapping JSON text data for export.
struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
