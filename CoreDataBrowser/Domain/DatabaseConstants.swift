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
    
    static let entityQuery = "SELECT name FROM sqlite_master WHERE type='table';"
    static let walCheckpointQuery = "PRAGMA wal_checkpoint(FULL);"
    
    static func databaseContentQuery(table: String, limit: Int) -> String {
        "SELECT * FROM \(table) LIMIT \(limit);"
    }
    
    static func fetchColumnTypeQuery(table: String) -> String {
        "PRAGMA table_info(\(table));"
    }
    
    static let excludedTables = [
        "Z_METADATA", "Z_PRIMARYKEY", "Z_MODELCACHE",
        "ACHANGE", "ATRANSACTION", "ATRANSACTIONSTRING"
    ]
    
    static let excludedColumns = ["Z_PK", "Z_ENT", "Z_OPT"]
}
