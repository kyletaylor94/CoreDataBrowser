//
//  SQLiteExecutor.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation
import SQLite3

final class SQLiteExecutor {
    private let blobDecoder: BlobDecoder
    
    init(blobDecoder: BlobDecoder) {
        self.blobDecoder = blobDecoder
    }
    
    /// Fetches the names of all entities (tables) in the SQLite database located at the given URL.
    /// - Parameter databaseURL: The URL of the SQLite database file.
    /// - Returns: An array of entity (table) names present in the database.
    func fetchEntities(in databaseURL: URL) -> [String] {
        return executeMultiple(at: databaseURL, query: DatabaseConstants.entityQuery) { statement in
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
            return ""
        }.filter { !$0.isEmpty }
    }
    
    /// Fetches the column names and their corresponding data types for a specified table in the SQLite database.
    /// - Parameters:
    ///  - databaseURL: The URL of the SQLite database file.
    ///  - table: The name of the table for which to fetch column information.
    ///  - Returns: A tuple containing two arrays: the first array contains the column names, and the second array contains the corresponding data types for those columns.
    func fetchColumnsWithTypes(databaseURL: URL, table: String) -> ([String], [String]) {
        var columns: [String] = []
        var types: [String] = []
        
        let results = executeMultiple(at: databaseURL, query: DatabaseConstants.fetchColumnTypeQuery(table: table)) { statement -> (String, String)? in
            guard let name = sqlite3_column_text(statement, 1),
                  let type = sqlite3_column_text(statement, 2) else {
                return nil
            }
            return (String(cString: name), String(cString: type))
        }
        
        for result in results {
            if let (column, type) = result {
                columns.append(column)
                types.append(type)
            }
        }
        return (columns, types)
    }
    
    /// Fetches whether each column of a specified table is nullable (i.e. NOT declared `NOT NULL`),
    /// using SQLite's `PRAGMA table_info` introspection, in the same column order as
    /// `fetchColumnsWithTypes`. Used to mark optional attributes in the Schema Graph.
    /// - Parameters:
    ///  - databaseURL: The URL of the SQLite database file.
    ///  - table: The name of the table for which to fetch column nullability.
    /// - Returns: An array of `Bool`, one per column, where `true` means the column is nullable/optional.
    func fetchColumnNullability(databaseURL: URL, table: String) -> [Bool] {
        executeMultiple(at: databaseURL, query: DatabaseConstants.fetchColumnTypeQuery(table: table)) { statement -> Bool in
            // PRAGMA table_info columns: 0 cid, 1 name, 2 type, 3 notnull, 4 dflt_value, 5 pk
            sqlite3_column_int(statement, 3) == 0
        }
    }
    
    /// Fetches the foreign key constraints defined on a specified table using SQLite's built-in
    /// `PRAGMA foreign_key_list` introspection. Core Data's SQLite store encodes to-one relationships
    /// as real foreign key constraints (e.g. a `ZBOOK` table having a `ZAUTHOR` column referencing
    /// `ZAUTHOR(Z_PK)`), so this gives us an accurate way to reconstruct entity relationships without
    /// needing access to the compiled `.momd` model.
    /// - Parameters:
    ///  - databaseURL: The URL of the SQLite database file.
    ///  - table: The name of the table for which to fetch foreign key constraints.
    /// - Returns: An array of `DBForeignKey` describing each foreign key constraint found on the table.
    func fetchForeignKeys(databaseURL: URL, table: String) -> [DBForeignKey] {
        executeMultiple(at: databaseURL, query: "PRAGMA foreign_key_list(\"\(table)\");") { statement -> DBForeignKey? in
            guard let destinationTable = sqlite3_column_text(statement, 2),
                  let fromColumn = sqlite3_column_text(statement, 3) else {
                return nil
            }
            let toColumn = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? "Z_PK"
            return DBForeignKey(
                column: String(cString: fromColumn),
                destinationTable: String(cString: destinationTable),
                destinationColumn: toColumn
            )
        }.compactMap { $0 }
    }
    
    /// Fetches all rows of data from a specified table in the SQLite database.
    /// - Parameters:
    /// - databaseURL: The URL of the SQLite database file.
    /// - query: The SQL query to execute for fetching the rows (e.g., "SELECT * FROM tableName").
    /// - Returns: An array of rows, where each row is represented as an array of strings corresponding to the column values.
    func fetchRows(at databaseURL: URL, query: String) -> [[String]] {
        var rows: [[String]] = []
        execute(at: databaseURL, query: query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String] = []
                for i in 0..<sqlite3_column_count(statement) {
                    row.append(extractColumnValue(from: statement, at: i))
                }
                rows.append(row)
            }
        }
        return rows
    }
    
    /// Executes a given SQL query on the SQLite database located at the specified URL and processes the resulting statement using a provided closure.
    /// - Parameters:
    /// - databaseURL: The URL of the SQLite database file.
    ///  - query: The SQL query to execute.
    ///  - process: A closure that takes an `OpaquePointer` to the prepared statement
    ///  and returns a value of type `T` after processing the statement (e.g., fetching rows, extracting column information).
    func execute<T>(at databaseURL: URL, query: String, process: (OpaquePointer) -> T) -> T? {
        var db: OpaquePointer?
        var statement: OpaquePointer?
        
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK,
              let db = db else {
            sqlite3_close(db)
            return nil
        }
        
        defer { sqlite3_close(db) }
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK,
               let statement = statement else {
             return nil
         }
        
        defer { sqlite3_finalize(statement) }
        return process(statement)
    }
    
    /// Executes a given SQL query on the SQLite database located at the specified URL and processes multiple rows of results using a provided closure.
    /// - Parameters:
    /// - databaseURL: The URL of the SQLite database file.
    ///  - query: The SQL query to execute.
    ///   - processRow: A closure that takes an `OpaquePointer` to the prepared statement and returns a value of type `T` after processing each row of the result set.
    ///   - Returns: An array of values of type `T`, where each value corresponds to a processed row from the result set of the executed query.
    func executeMultiple<T>(at databaseURL: URL, query: String, processRow: (OpaquePointer) -> T) -> [T] {
        var results: [T] = []
        execute(at: databaseURL, query: query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(processRow(statement))
            }
        }
        return results
    }
    
    /// Extracts the value of a column from a SQLite statement at a specified index and converts it to a string representation based on the column's data type.
    /// - Parameters:
    /// - statement: An `OpaquePointer` to the prepared SQLite statement from which to extract the column value.
    /// - index: The index of the column from which to extract the value.
    /// - Returns: A string representation of the column value, formatted according to its data type (e.g., integer, float, text, blob). If the value is null or cannot be decoded, it returns a default string indicating the type or null status.
    private func extractColumnValue(from statement: OpaquePointer, at index: Int32) -> String {
        let type = sqlite3_column_type(statement, index)
        
        switch type {
        case SQLITE_INTEGER:
            return String(sqlite3_column_int64(statement, index))
            
        case SQLITE_FLOAT:
            return String(sqlite3_column_double(statement, index))
            
        case SQLITE_TEXT:
            if let value = sqlite3_column_text(statement, index) {
                return String(cString: value)
            }
            return "NULL"
            
        case SQLITE_BLOB:
            let bytes = sqlite3_column_blob(statement, index)
            let length = sqlite3_column_bytes(statement, index)
            
            if let bytes {
                let data = Data(bytes: bytes, count: Int(length))
                if let decoded = blobDecoder.decode(from: data) {
                    return decoded
                }
                return "BLOB (\(length) bytes)"
            }
            return "BLOB"
            
        default:
            return "NULL"
        }
    }
}
