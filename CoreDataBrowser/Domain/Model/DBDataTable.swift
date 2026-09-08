//
//  CoreDataTable.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 03..
//

import Foundation

struct DBDataTable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let columns: [String]
    let rows: [[String]]
    let types: [String]
    let fileSize: Int64
    /// The URL of the underlying SQLite database file this table was read from. Used to look up
    /// additional metadata (e.g. foreign keys for the Schema Graph) without re-scanning the file system.
    let fileURL: URL?
    /// Whether each column (in the same order as `columns`/`types`) is nullable/optional, read from
    /// SQLite's `PRAGMA table_info`. Used to mark optional attributes in the Schema Graph.
    let isOptional: [Bool]
    
    init(name: String, columns: [String], rows: [[String]], types: [String], fileSize: Int64, fileURL: URL? = nil, isOptional: [Bool] = []) {
        self.name = name
        self.columns = columns
        self.rows = rows
        self.types = types
        self.fileSize = fileSize
        self.fileURL = fileURL
        self.isOptional = isOptional
    }
    
    /// Computed property to format columns with their types. Removes the "Z" prefix from column names if present and formats them as "ColumnName (Type)"
    /// Example: "ZNAME (TEXT)", "ZAGE (INTEGER)"
    var formattedColumns: [String] {
        zip(columns, types).map { column, type in
            let cleanColumn = FormattingHelper.removeZPrefix(from: column)
            return "\(cleanColumn) (\(type))"
        }
    }
}
