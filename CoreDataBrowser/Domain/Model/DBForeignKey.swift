//
//  DBForeignKey.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation

/// Represents a single foreign key constraint read directly from a SQLite table via `PRAGMA foreign_key_list`.
/// Core Data's SQLite store encodes to-one relationships as real foreign key constraints, so this gives us
/// an accurate, model-free way to discover relationships between entity tables (e.g. "ZBOOK" -> "ZAUTHOR").
struct DBForeignKey: Hashable {
    /// The column on the source table holding the foreign key value (e.g. "ZAUTHOR").
    let column: String
    /// The name of the destination table the foreign key references (e.g. "ZAUTHOR").
    let destinationTable: String
    /// The column on the destination table being referenced (usually "Z_PK").
    let destinationColumn: String
}
