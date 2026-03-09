//
//  Constants.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 10..
//

import Foundation
import SQLite3

enum Constants {
    static let tableDidRefresh = "tableDidRefresh"
    static let sqliteSequence = "sqlite_sequence"
    static let sqlite = "sqlite"
    
    static let SIMULATOR_PATH = "Library/Developer/CoreSimulator/Devices"
    static let SIMULATOR_APPS_PATH = "data/Containers/Data/Application"
    
    static  let ENTITY_QUERY = "SELECT name FROM sqlite_master WHERE type='table';"
    static let VAL_CHECKPOINT_QUERY = "PRAGMA wal_checkpoint(FULL);"
    
    static let STORE = "store"
    static let DOCUMENTS = "Documents"
    
    static func databaseContentQuery(table: String, limit: Int) -> String {
        "SELECT * FROM \(table) LIMIT \(limit);"
    }
    
    static func fetchColumnTypeQuery(table: String) -> String {
        "PRAGMA table_info(\(table));"
    }
    
    static let excludedTables = [
        "Z_METADATA",
        "Z_PRIMARYKEY",
        "Z_MODELCACHE",
        "ACHANGE",
        "ATRANSACTION",
        "ATRANSACTIONSTRING"
    ]
    
    static let excludedColumns = ["Z_PK", "Z_ENT", "Z_OPT"]
    static let runTimeReplacing = "com.apple.CoreSimulator.SimRuntime."
    
    static let LIBRARY = "Library"
    static let LIBRARY_PREFENCES_PATH = "\(LIBRARY)/Preferences"
    static let LIBRARY_APPLICATIONSUPPORT_PATH = "\(LIBRARY)/Application Support"
    static let PLIST_PATH_EXTENSION = "plist"
    static let devicePList = "device.\(PLIST_PATH_EXTENSION)"
}
