//
//  JSONExportDocument.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 16..
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    
    let data: Data
    
    init(table: DBDataTable, format: UTType) {
        data = Self.exportData(table: table, format: format)
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
    
    private static func exportData(table: DBDataTable, format: UTType) -> Data {
        switch format {
        case .json:
            return exportJSON(table)
            
        case .commaSeparatedText:
            return exportCSV(table)
            
        default:
            return Data()
        }
    }
    
    static func exportJSON(_ table: DBDataTable) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(DBDataExport(table: table))) ?? Data()
    }
    
    private static func exportCSV(_ table: DBDataTable) -> Data {
        func escape(_ value: String) -> String {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            
            if escaped.contains(",") ||
                escaped.contains("\"") ||
                escaped.contains("\n") ||
                escaped.contains("\r") {
                return "\"\(escaped)\""
            }
            return escaped
        }
        
        let header = table.columns
            .map { FormattingHelper.removeZPrefix(from: $0) }
            .map(escape)
            .joined(separator: ",")
        
        let rows = table.rows
            .map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\n")
        
        return Data("\(header)\n\(rows)".utf8)
    }
}
