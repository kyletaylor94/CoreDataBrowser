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
    
    /// Computed property to format columns with their types. Removes the "Z" prefix from column names if present and formats them as "ColumnName (Type)"
    /// Example: "ZNAME (TEXT)", "ZAGE (INTEGER)"
    var formattedColumns: [String] {
        zip(columns, types).map { column, type in
            let cleanColumn = removeZPrefix(from: column)
            return "\(cleanColumn) (\(type))"
        }
    }
    
    /// Helper method to remove "Z" prefix from column names if it exists and is followed by an uppercase letter
    /// Example: "ZNAME" becomes "NAME", but "Zname" remains "Zname"
    private func removeZPrefix(from column: String) -> String {
        guard column.count >= 2,
              column.first == "Z",
              column.dropFirst().first?.isUppercase == true else {
            return column
        }
        return String(column.dropFirst())
    }
}
