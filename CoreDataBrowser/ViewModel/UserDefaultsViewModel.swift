//
//  UserDefaultsViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation

enum UserDefaultsError: Error {
    case fileNotFound(URL)
    case invalidFormat(URL)
    case readError(URL)
    case cannotLoadApps(URL)
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound(let url):
            return "UserDefaults file not found at: \(url.path)"
        case .invalidFormat(let url):
            return "Invalid UserDefaults file format at: \(url.path)"
        case .readError(let url):
            return "Error reading UserDefaults file at: \(url.path)"
        case .cannotLoadApps(let url):
            return "Cannot load apps from: \(url.path)"
        }
    }
}

@Observable
class UserDefaultsViewModel {
    var userDefaultsTable: [DBDataTable] = []
    var selectedUserDefaultTable: DBDataTable? = nil
    var isLoading = false
    var hasError = false
    var error: UserDefaultsError? = nil
    
    private let fileManager = FileManager.default
    
    func refreshUserDefaults() {
        if let selectedUserDefaultTable,
           let updated = userDefaultsTable.first(where: { $0.name == selectedUserDefaultTable.name }) {
            DispatchQueue.main.async { [weak self] in
                self?.userDefaultsTable = self?.userDefaultsTable ?? []
                NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
            }
        }
    }
    
    func loadUserDefaults(for device: SimulatorDevice) {
        isLoading = true
        defer { isLoading = false }
        
        let preferencesPath = device.path
            .appendingPathComponent(Constants.SIMULATOR_APPS_PATH)
        
        guard let appFolders = try? fileManager.contentsOfDirectory(at: preferencesPath, includingPropertiesForKeys: nil)
        else {
            error = .cannotLoadApps(preferencesPath)
            hasError = true
            return
        }
        
        for appFolder in appFolders {
            let libraryPath = appFolder.appendingPathComponent(Constants.LIBRARY_PREFENCES_PATH)
            guard fileManager.fileExists(atPath: libraryPath.path) else { continue }
            
            guard let contents = try? fileManager.contentsOfDirectory(at: libraryPath, includingPropertiesForKeys: nil) else {
                error = .readError(libraryPath)
                hasError = true
                continue
            }
            for file in contents where file.pathExtension == Constants.PLIST_PATH_EXTENSION {
                guard !file.lastPathComponent.hasPrefix("com.apple.") else { continue }
                
                guard let dict = NSDictionary(contentsOf: file) as? [String: Any] else {
                    error = .invalidFormat(file)
                    hasError = true
                    continue
                }
                
                let rows = extractValuesFromUserDefaults(from: dict)
                createUserDefaultsTable(file: file, rows: rows)
            }
        }
    }
    
    private func createUserDefaultsTable(file: URL, rows: [[String]]) {
        let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
        let table = DBDataTable(
            name: "UserDefaults - \(file.deletingPathExtension().lastPathComponent)",
            columns: ["Key", "Value", "Type"],
            rows: rows,
            types: ["", "", ""],
            fileSize: fileSize
        )
        
        if !userDefaultsTable.contains(where: { $0.name == table.name }) {
            self.userDefaultsTable.append(table)
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
