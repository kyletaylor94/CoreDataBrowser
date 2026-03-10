//
//  SwiftDataViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation
import SQLite3

enum SwiftDataError: Error {
    case cannotLoadApps(URL)
    case cannotOpenDatabase(URL)
    case queryFailed(String)
    case invalidData(URL)
    
    var localizedDescription: String {
        switch self {
        case .cannotLoadApps(let url):
            return "Cannot load apps from: \(url.path)"
        case .cannotOpenDatabase(let url):
            return "Cannot open SwiftData database at: \(url.path)"
        case .queryFailed(let query):
            return "Query failed: \(query)"
        case .invalidData(let url):
            return "Invalid SwiftData store at: \(url.path)"
        }
    }
}

@MainActor
@Observable
class DBDataViewModel {
    var selectedTable: DBDataTable? = nil
    var secondaryTable: DBDataTable? = nil
    var swiftDataTables: [DBDataTable] = []
    var coreDataTables: [DBDataTable] = []

    var isLoading = false
    var hasError = false
    var error: SwiftDataError? = nil
    
    private let fileManager = FileManager.default
    private let pathManager: PathManager
    
    init(pathManager: PathManager) {
        self.pathManager = pathManager
    }
    
    func refresh(selectedDevice: SimulatorDevice?) {
        guard let selectedDevice else { return }
        loadSimulatorApps(for: selectedDevice)
        refreshCoreDataTables()
    }
    
    func loadSimulatorApps(for device: SimulatorDevice) {
        isLoading = true
        defer { isLoading = false }
        coreDataTables.removeAll()
        loadDataStores(device: device, fileExtension: Constants.sqlite, storage: &coreDataTables, shouldExecuteCheckpoint: false)
    }
    
    private func refreshCoreDataTables() {
        if let selectedTable,
           let updated = coreDataTables.first(where: { $0.name == selectedTable.name }) {
            self.coreDataTables = self.coreDataTables
            NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
        }
    }
    
    func loadSwiftData(for device: SimulatorDevice) {
        isLoading = true
        defer { isLoading = false }
        swiftDataTables.removeAll()
        loadDataStores(device: device, fileExtension: Constants.STORE, storage: &swiftDataTables, shouldExecuteCheckpoint: true)
    }
    
    private func filteredTableName(file: URL) -> [String] {
        let tableNames = fetchEntities(in: file)
            .filter { !Constants.excludedTables.contains($0.uppercased()) }
            .filter { !$0.lowercased().contains(Constants.sqliteSequence) }
        return tableNames
    }
    
    private func filteredRows(rows: [[String]], indicesToKeep: [Int]) -> [[String]] {
        rows.map { row in
            indicesToKeep.compactMap { index in
                guard index < row.count else { return nil }
                return row[index]
            }
        }
    }
    
    private func fetchEntities(in databaseURL: URL) -> [String] {
        return executeSQLiteMultiple(at: databaseURL, query: Constants.ENTITY_QUERY) { statement in
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
            return ""
        }.filter { !$0.isEmpty }
    }
    
    private func executeSQLiteMultiple<T>(at databaseURL: URL, query: String, processRow: (OpaquePointer) -> T) -> [T] {
        var results: [T] = []
        executeSQLite(at: databaseURL, query: query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(processRow(statement))
            }
        }
        return results
    }
    
    private func executeSQLite<T>(at databaseURL: URL, query: String, process: (OpaquePointer) -> T) -> T? {
        var db: OpaquePointer?
        var statement: OpaquePointer?
        var result: T?
        
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK,
              let db = db else {
            error = .cannotOpenDatabase(databaseURL)
            hasError = true
            sqlite3_close(db)
            return nil
        }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK,
           let statement = statement {
            result = process(statement)
            sqlite3_finalize(statement)
        } else {
            error = .queryFailed(query)
            hasError = true
        }
        
        sqlite3_close(db)
        return result
    }
    
    private func fetchDatabaseContent(from databaseURL: URL, table: String, limit: Int = 50) -> (columns: [String], types: [String], rows: [[String]]) {
        let (columns, types) = fetchColumnsWithTypes(databaseURL: databaseURL, table: table)
        let rows = fetchRows(at: databaseURL, query: Constants.databaseContentQuery(table: table, limit: limit))
        
        return (columns, types, rows)
    }
    
    private func fetchColumnsWithTypes(databaseURL: URL, table: String) -> ([String], [String]) {
        var columns: [String] = []
        var types: [String] = []
        
        let results = executeSQLiteMultiple(at: databaseURL, query: Constants.fetchColumnTypeQuery(table: table)) { statement -> (String, String)? in
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
    
    private func fetchRows(at databaseURL: URL, query: String) -> [[String]] {
        var rows: [[String]] = []
        executeSQLite(at: databaseURL, query: query) { statement in
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
                
                if let decoded = decodeCustomObject(from: data) {
                    return decoded
                }
                return "BLOB (\(length) bytes)"
            }
            return "BLOB"
            
        default:
            return "NULL"
        }
    }
    
    private func createDBTable(tableName: String, indicesToKeep: [Int], columns: [String], rows: [[String]], types: [String], fileURL: URL) -> DBDataTable {
        let fileSize = (try? fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
        return DBDataTable(
            name: tableName,
            columns: indicesToKeep.map { columns[$0] },
            rows: filteredRows(rows: rows, indicesToKeep: indicesToKeep),
            types: indicesToKeep.map { types[$0] },
            fileSize: fileSize
        )
    }
    
    private func findDataStores(in directories: [URL], withExtension ext: String) -> [URL] {
        var results: [URL] = []
        
        for dir in directories {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            if let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in contents where file.pathExtension == ext {
                    if !results.contains(file) {
                        results.append(file)
                    }
                }
            }
        }
        return results
    }
    
    private func loadDataStores(device: SimulatorDevice, fileExtension: String, storage: inout [DBDataTable], shouldExecuteCheckpoint: Bool = false) {
        let appsPath = device.path.appendingPathComponent(Constants.SIMULATOR_APPS_PATH)
        guard let appFolders = try? fileManager.contentsOfDirectory(at: appsPath, includingPropertiesForKeys: nil) else {
            error = .cannotLoadApps(appsPath)
            hasError = true
            return
        }
        
        let dataPath = fileExtension == Constants.STORE ? pathManager.swiftDataPath : pathManager.coreDataPath
        
        for appFolder in appFolders {
            let appDataPath = appFolder.appendingPathComponent(Constants.DOCUMENTS)
            let libraryPath = appFolder.appendingPathComponent(dataPath)
            let storeFiles = findDataStores(in: [appDataPath, libraryPath], withExtension: fileExtension)
            
            for file in storeFiles {
                if shouldExecuteCheckpoint {
                    executeSQLite(at: file, query: Constants.VAL_CHECKPOINT_QUERY) { _ in }
                }
                
                for tableName in filteredTableName(file: file) {
                    let (columns, types, rows) = fetchDatabaseContent(from: file, table: tableName)
                    let indicesToKeep = columns.enumerated()
                        .filter { !Constants.excludedColumns.contains($0.element.uppercased()) }
                        .map { $0.offset }
                    
                    let table = createDBTable(tableName: tableName, indicesToKeep: indicesToKeep, columns: columns, rows: rows, types: types, fileURL: file)
                    
                    if !storage.contains(table) {
                        storage.append(table)
                    }
                }
            }
        }
    }
    
    private func decodeCustomObject(from data: Data) -> String? {
        // try with NSKeyedUnarchiver(Core Data Transformable)
        if let object = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [
            NSString.self,
            NSNumber.self,
            NSArray.self,
            NSDictionary.self,
            NSData.self,
            NSURL.self,
            NSDate.self
        ], from: data) {
            return formatDecodedObject(object)
        }
        
        // try to interpret as JSON
        if let json = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        //try to interpret as Property List
        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) {
            return "\(plist)"
        }
        
        //try to read as UTF-8 string
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    private func formatDecodedObject(_ object: Any) -> String {
        switch object {
        case let dict as [AnyHashable: Any]:
            let pairs = dict.map { "\($0): \($1)" }.joined(separator: ", ")
            return "{\(pairs)}"
            
        case let array as [Any]:
            let items = array.map { "\($0)" }.joined(separator: ", ")
            return "[\(items)]"
            
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
            
        case let url as URL:
            return url.absoluteString
            
        default:
            return "\(object)"
        }
    }
}
