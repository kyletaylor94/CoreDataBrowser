//
//  SimulatorViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import Foundation
import SwiftUI
import SQLite3
import Combine

enum CustomErrorTypes: LocalizedError {
    case cannotAccessDevicesFolder
    case cannotReadPlist(URL)
    case cannotOpenDatabase(URL)
    case cannotLoadApps(URL)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .cannotAccessDevicesFolder:
            return "Cannot access CoreSimulator devices folder."
        case .cannotReadPlist(let url):
            return "Failed to read device.plist at: \(url.lastPathComponent)"
        case .cannotOpenDatabase(let url):
            return "Failed to open database: \(url.lastPathComponent)"
        case .cannotLoadApps(let url):
            return "Failed to load apps for simulator: \(url.lastPathComponent)"
        case .unknown(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}

@Observable
class ViewModel {
    var devices: [SimulatorDevice] = []
    var tables: [CoreDataTable] = []
    var userDefaultsTable: [UserDefaultsTable] = []
    var currentError: CustomErrorTypes? = nil
    var shouldShowError: Bool = false
    
    var db: OpaquePointer?
    var statement: OpaquePointer?
    
    func refresh(selectedDevice: SimulatorDevice?, selectedTable: CoreDataTable?, selectedUserDefaultsTable: UserDefaultsTable?) {
        loadSimulators()
        guard let selectedDevice else { return }
        loadSimulatorApps(for: selectedDevice)
        loadUserDefaults(for: selectedDevice)
        
        if let selectedTable,
           let updated = tables.first(where: { $0.name == selectedTable.name }) {
            DispatchQueue.main.async { [weak self] in
                self?.tables = self?.tables ?? []
                NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
            }
        }
        
        if let selectedUserDefaultsTable,
           let updated = userDefaultsTable.first(where: { $0.name == selectedUserDefaultsTable.name }) {
            DispatchQueue.main.async { [weak self] in
                self?.userDefaultsTable = self?.userDefaultsTable ?? []
                NotificationCenter.default.post(name: .userDefaultsTableDidRefresh, object: updated)
            }
        }
    }
    
    func runTimeTextReplacing(device: SimulatorDevice) -> String {
        return device.runTime.replacingOccurrences(
            of: "com.apple.CoreSimulator.SimRuntime.",
            with: "")
    }
    
    private func setError(_ error: CustomErrorTypes) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentError = error
            self.shouldShowError = true
            print("\(error.localizedDescription)")
        }
    }
    
    func loadSimulators() {
        let basePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(Constants.shared.SIMULATOR_PATH)
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil) else {
            setError(.cannotAccessDevicesFolder)
            return
        }
        
        var loadedDevices: [SimulatorDevice] = []
        
        for deviceURL in contents {
            let plistURL = deviceURL.appendingPathComponent("device.plist")
            guard FileManager.default.fileExists(atPath: plistURL.path) else { continue }
            
            do {
                let data = try Data(contentsOf: plistURL)
                let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                guard let dict = plist as? [String: Any] else { continue }
                
                let (name, state, runtime) = checkKeys(dict: dict)
                
                loadedDevices.append(
                    SimulatorDevice(
                        id: UUID(),
                        name: name,
                        state: state,
                        runTime: runtime,
                        path: deviceURL
                    )
                )
            } catch {
                setError(.cannotReadPlist(plistURL))
            }
        }
        self.sortedDevices(devices: Array(Set(loadedDevices)))
    }
    
    private func sortedDevices(devices: [SimulatorDevice]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.devices = devices.sorted(by: { $0.name < $1.name })
        }
    }
    
    private func checkKeys(dict: [String: Any]) -> (String, String, String) {
        let safeDict = dict.compactMapValues { $0 as? String }
        let name = safeDict["name"] ?? "N/A"
        let runtime = safeDict["runtime"] ?? "Unknown"
        
        let state: String
        if let s = safeDict["state"] {
            state = s
        } else if let n = dict["state"] as? Int {
            state = (n == 1) ? "Shutdown" : "Booted"
        } else {
            state = "Unknown"
        }
        
        return (name, state, runtime)
    }
    
    func loadSimulatorApps(for device: SimulatorDevice) {
        self.tables.removeAll()
        
        let appsPath = device.path
            .appendingPathComponent(Constants.shared.SIMULATOR_APPS_PATH)
        
        guard let appFolders = try? FileManager.default.contentsOfDirectory(at: appsPath, includingPropertiesForKeys: nil) else {
            setError(.cannotLoadApps(device.path))
            return
        }
        
        for appFolder in appFolders {
            let appDataPath = appFolder.appendingPathComponent("Documents")
            let libraryPath = appFolder.appendingPathComponent("Library/Application Support")
            
            ///Looking for the Core Data's SQLite files
            let sqliteFiles = findSQLiteFiles(in: [appDataPath, libraryPath])
            
            if !sqliteFiles.isEmpty {
                for file in sqliteFiles {
                    for tableName in filteredTableName(file: file) {
                        let (columns, types, rows) = self.fetchCoreDatabaseContent(from: file, table: tableName)
                        
                        let indicesToKeep = columns.enumerated()
                            .filter { !Constants.shared.excludedColumns.contains($0.element.uppercased()) }
                            .map { $0.offset }
                        
                        createCoreDataTable(
                            tableName: tableName,
                            indicesToKeep: indicesToKeep,
                            columns: columns,
                            rows: rows,
                            types: types
                        )
                    }
                }
            }
        }
    }
    
    private func createCoreDataTable(tableName: String, indicesToKeep: [Int], columns: [String], rows: [[String]], types: [String]) {
        let table = CoreDataTable(
            name: tableName,
            columns: indicesToKeep.map { columns[$0] },
            rows: filteredRows(rows: rows, indicesToKeep: indicesToKeep),
            types: indicesToKeep.map { types[$0] }
        )
        
        if !tables.contains(table) {
            self.tables.append(table)
        }
    }
    
    private func filteredTableName(file: URL) -> [String] {
        let tableNames = self.fetchCoreDataEntities(in: file)
            .filter { !Constants.shared.excludedTables.contains($0.uppercased()) }
            .filter { !$0.lowercased().contains("sqlite_sequence") }
        
        return tableNames
    }
    
    private func filteredRows(rows: [[String]], indicesToKeep: [Int]) -> [[String]] {
        return rows.map { row in
            indicesToKeep.compactMap { index -> String? in
                guard index < row.count else { return nil }
                return row[index]
            }
        }
    }
    
    private func findSQLiteFiles(in directories: [URL]) -> [URL] {
        var results: [URL] = []
        for dir in directories {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }
            
            if let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in contents where file.pathExtension == "sqlite" {
                    if !results.contains(file) {
                        results.append(file)
                    }
                }
            }
        }
        return results
    }
    
    private func fetchCoreDataEntities(in databaseURL: URL) -> [String] {
        let query = "SELECT name FROM sqlite_master WHERE type='table';"
        var tables: [String] = []
        
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(statement, 0) {
                        tables.append(String(cString: cString))
                    }
                }
            }
            sqlite3_finalize(statement)
        } else {
            setError(.cannotOpenDatabase(databaseURL))
        }
        sqlite3_close(db)
        return tables
    }
    
    func fetchCoreDatabaseContent(from databaseURL: URL, table: String, limit: Int = 50) -> (columns: [String], types: [String], rows: [[String]]) {
        let query = "SELECT * FROM \(table) LIMIT \(limit);"
        
        let (columns, types) = fetchColumnsWithTypes(databaseURL: databaseURL, table: table)
        let rows = fetchRows(query: query)
        
        sqlite3_close(db)
        return (columns, types, rows)
    }
    
    ///Fetch column names and their types
    private func fetchColumnsWithTypes(databaseURL: URL ,table: String) -> ([String], [String]) {
        var columns: [String] = []
        var types: [String] = []
        
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            if sqlite3_prepare_v2(db, "PRAGMA table_info(\(table));", -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let name = sqlite3_column_text(statement, 1),
                       let type = sqlite3_column_text(statement, 2) {
                        columns.append(String(cString: name))
                        types.append(String(cString: type))
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return (columns, types)
    }
    
    private func fetchRows(query: String) -> [[String]] {
        var rows: [[String]] = []
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String] = []
                for i in 0..<sqlite3_column_count(statement) {
                    if let value = sqlite3_column_text(statement, i) {
                        row.append(String(cString: value))
                    } else {
                        row.append("NULL")
                    }
                }
                rows.append(row)
            }
        }
        sqlite3_finalize(statement)
        return rows
    }
    
    func loadUserDefaults(for device: SimulatorDevice) {
        let preferencesPath = device.path
            .appendingPathComponent(Constants.shared.SIMULATOR_APPS_PATH)
        
        guard let appFolders = try? FileManager.default.contentsOfDirectory(at: preferencesPath, includingPropertiesForKeys: nil)
        else { return }
        
        userDefaultsTable.removeAll()
        
        for appFolder in appFolders {
            let libraryPath = appFolder.appendingPathComponent("Library/Preferences")
            guard FileManager.default.fileExists(atPath: libraryPath.path) else { continue }
            
            if let contents = try? FileManager.default.contentsOfDirectory(at: libraryPath, includingPropertiesForKeys: nil) {
                for file in contents where file.pathExtension == "plist" {
                    guard !file.lastPathComponent.hasPrefix("com.apple.") else { continue }
                    
                    if let dict = NSDictionary(contentsOf: file) as? [String: Any] {
                        let rows = extractValuesFromUserDefaults(from: dict)
                        createUserDefaultsTable(file: file, rows: rows)
                    }
                }
            }
        }
    }
    
    private func extractValuesFromUserDefaults(from dict: [String : Any]) -> [[String]] {
        var rows: [[String]] = []
        
        for (key, value) in dict {
            let type = typeDescription(for: value)
            let stringValue = stringValue(for: value)
            rows.append([key, stringValue, type])
        }
        
        return rows
    }
    
    private func createUserDefaultsTable(file: URL, rows: [[String]]) {
        let table = UserDefaultsTable(
            name: "UserDefaults - \(file.deletingPathExtension().lastPathComponent)",
            columns: ["Key", "Value", "Type"],
            rows: rows,
            types: ["", "", ""]
        )
        
        if !userDefaultsTable.contains(where: { $0.name == table.name }) {
            self.userDefaultsTable.append(table)
        }
    }
    
    private func typeDescription(for value: Any) -> String {
        if let number = value as? NSNumber {
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? "Bool" : "Int"
        }
        
        switch value {
        case is String: return "String"
        case is Double: return "Double"
        case is Float: return "Float"
        case is Date: return "Date"
        case is Data: return "Data"
        case is [Any]: return "Array"
        case is [String : Any]: return "Dictionary"
        default: return String(describing: type(of: value))
        }
    }
    
    private func stringValue(for value: Any) -> String {
        if let boolVaue = value as? Bool {
            return boolVaue ? "true" : "false"
        }
        
        if let data = value as? String {
            return "Data \(data.count) bytes"
        }
        
        if let numberValue = value as? NSNumber {
            if CFGetTypeID(numberValue) == CFBooleanGetTypeID() {
                return numberValue.boolValue ? "true" : "false"
            }
            return numberValue.stringValue
        }
        
        if let array = value as? [Any] {
            return array.map { String(describing: $0) }.joined(separator: ", ")
        }
        
        if let dict = value as? [String: Any] {
            return dict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        }
        
        return String(describing: value)
    }
}

extension Notification.Name {
    static let tableDidRefresh = Notification.Name(Constants.shared.tableDidRefresh)
    static let userDefaultsTableDidRefresh = Notification.Name(Constants.shared.userDefaultsTableDidRefresh)
}
