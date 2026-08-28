//
//  ClipboardHelper.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 5: Copy/paste helper that works on macOS (AppKit) targets.
//

import Foundation
#if os(macOS)
import AppKit
#endif

enum ClipboardHelper {
    /// Writes a string to the system clipboard.
    static func write(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }

    /// Reads a string from the system clipboard, if present.
    static func readString() -> String? {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }
}
