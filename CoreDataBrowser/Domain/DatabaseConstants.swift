//
//  DatabaseConstants.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum DatabaseConstants {
    static let sqliteSequence = "sqlite_sequence"
    static let sqlite = "sqlite"
    static let store = "store"
    static let documents = "Documents"
    
    /// A SQL query to retrieve the names of all tables in the SQLite database. This query is used to list the entities (tables) present in the database.
    static let entityQuery = "SELECT name FROM sqlite_master WHERE type='table';"
    
    /// A SQL query to perform a checkpoint operation on the Write-Ahead Logging (WAL) mode of SQLite. This query forces SQLite to flush the WAL file and merge its contents back into the main database file, which can help reduce the size of the WAL file and improve performance.
    /// The `FULL` option ensures that the checkpoint operation is performed fully, meaning that all transactions in the WAL file are processed and merged into the main database file.
    /// This query is typically used to maintain the health and performance of the database, especially when using WAL mode, by ensuring that the WAL file does not grow indefinitely and that changes are properly reflected in the main database file.
    static let walCheckpointQuery = "PRAGMA wal_checkpoint(FULL);"
    
    /// Generates a SQL query to fetch content from a specified table with a limit on the number of rows.
    /// - Parameters:
    ///  - table: The name of the table to query.
    ///  - limit: The maximum number of rows to return.
    ///  - Returns: A SQL query string to fetch the specified content.
    static func databaseContentQuery(table: String, limit: Int) -> String {
        "SELECT * FROM \(table) LIMIT \(limit);"
    }
    
    /// Generates a SQL query to fetch the column types of a specified table.
    /// - Parameter table: The name of the table to query.
    /// - Returns: A SQL query string to fetch the column types of the specified table.
    static func fetchColumnTypeQuery(table: String) -> String {
        "PRAGMA table_info(\(table));"
    }
    
    /// A list of table names that should be excluded from certain operations, such as display or querying, to avoid showing internal or irrelevant tables.
    /// This typically includes tables that are used internally by Core Data or SQLite and are not relevant to the user.
    /// The excluded tables include:
    /// - `Z_METADATA`: A table used by Core Data to store metadata about the data
    /// - `Z_PRIMARYKEY`: A table used by Core Data to manage primary keys for entities.
    ///  - `Z_MODELCACHE`: A table used by Core Data to cache the data model information.
    ///  - `ACHANGE`, `ATRANSACTION`, `ATRANSACTIONSTRING`: Tables that may be used for tracking changes or transactions in certain Core Data configurations.
    static let excludedTables = [
        "Z_METADATA", "Z_PRIMARYKEY", "Z_MODELCACHE",
        "ACHANGE", "ATRANSACTION", "ATRANSACTIONSTRING"
    ]
    
    static let excludedColumns = ["Z_PK", "Z_ENT", "Z_OPT"]
}
