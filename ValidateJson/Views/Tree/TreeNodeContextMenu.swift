//
//  TreeNodeContextMenu.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Phase 3 Enhancement: Context menu for tree nodes

import SwiftUI
import AppKit

/// Context menu actions for tree nodes
struct TreeNodeContextMenu: View {
    let node: JSONNode
    
    var body: some View {
        Group {
            // Copy value
            if let value = node.displayValue {
                Button("Copy Value") {
                    copyToClipboard(value)
                }
            }
            
            // Copy key
            if let key = node.key {
                Button("Copy Key") {
                    copyToClipboard(key)
                }
            }
            
            // Copy path
            Button("Copy JSON Path") {
                copyToClipboard(node.displayName)
            }
            
            Divider()
            
            // Copy as JSON
            Button("Copy as JSON") {
                copyNodeAsJSON()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func copyNodeAsJSON() {
        let jsonString = nodeToJSONString(node)
        copyToClipboard(jsonString)
    }
    
    private func nodeToJSONString(_ node: JSONNode) -> String {
        switch node.value {
        case .object(let dict):
            guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
                  let string = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return string
            
        case .array(let arr):
            guard let data = try? JSONSerialization.data(withJSONObject: arr, options: .prettyPrinted),
                  let string = String(data: data, encoding: .utf8) else {
                return "[]"
            }
            return string
            
        case .string(let str):
            return "\"\(str)\""
            
        case .number(let num):
            return "\(num)"
            
        case .bool(let bool):
            return "\(bool)"
            
        case .null:
            return "null"
        }
    }
}
