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
    
    func fetchEntities(in databaseURL: URL) -> [String] {
        return executeMultiple(at: databaseURL, query: DatabaseConstants.entityQuery) { statement in
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
            return ""
        }.filter { !$0.isEmpty }
    }
    
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
    
    func execute<T>(at databaseURL: URL, query: String, process: (OpaquePointer) -> T) -> T? {
        var db: OpaquePointer?
        var statement: OpaquePointer?
        var result: T?
        
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK,
              let db = db else {
            sqlite3_close(db)
            return nil
        }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK,
           let statement = statement {
            result = process(statement)
            sqlite3_finalize(statement)
        }
        
        sqlite3_close(db)
        return result
    }
    
    func executeMultiple<T>(at databaseURL: URL, query: String, processRow: (OpaquePointer) -> T) -> [T] {
        var results: [T] = []
        execute(at: databaseURL, query: query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(processRow(statement))
            }
        }
        return results
    }
    
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
