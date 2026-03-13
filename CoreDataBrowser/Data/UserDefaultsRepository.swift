//
//  SimulatorRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol UserDefaultsRepository {
    func loadUserDefaults(for device: SimulatorDevice) async throws -> [DBDataTable]
    func createUserDefaultsTable(file: URL, dict: [String: Any]) throws -> DBDataTable
    func extractValuesFromUserDefaults(from dict: [String: Any]) -> [[String]]
    func typeDescription(for value: Any) -> String
    func stringValue(for value: Any) -> String
}

final class UserDefaultsRepositoryImpl: UserDefaultsRepository {
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func loadUserDefaults(for device: SimulatorDevice) async throws -> [DBDataTable] {
        let preferencesPath = device.path
            .appendingPathComponent(PathConstants.simulatorAppsPath)
        
        guard let appFolders = try? fileManager.contentsOfDirectory(at: preferencesPath, includingPropertiesForKeys: nil) else {
            throw UserDefaultsError.cannotLoadApps(preferencesPath)
        }
        
        var tables: [DBDataTable] = []
        
        for appFolder in appFolders {
            let libraryPath = appFolder.appendingPathComponent(PathConstants.libraryPreferencesPath)
            guard fileManager.fileExists(atPath: libraryPath.path) else { continue }
            
            guard let contents = try? fileManager.contentsOfDirectory(at: libraryPath, includingPropertiesForKeys: nil) else {
                throw UserDefaultsError.readError(libraryPath)
            }
            
            for file in contents where file.pathExtension == PathConstants.plistExtension {
                guard !file.lastPathComponent.hasPrefix("com.apple.") else { continue }
                
                guard let dict = NSDictionary(contentsOf: file) as? [String: Any] else {
                    throw UserDefaultsError.invalidFormat(file)
                }
                
                let table = try createUserDefaultsTable(file: file, dict: dict)
                if !tables.contains(where: { $0.name == table.name }) {
                    tables.append(table)
                }
            }
        }
        return tables
    }
    
    func createUserDefaultsTable(file: URL, dict: [String: Any]) throws -> DBDataTable {
        let rows = extractValuesFromUserDefaults(from: dict)
        let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
        
        return DBDataTable(
            name: "UserDefaults - \(file.deletingPathExtension().lastPathComponent)",
            columns: ["Key", "Value", "Type"],
            rows: rows,
            types: ["", "", ""],
            fileSize: fileSize
        )
    }
    
    func extractValuesFromUserDefaults(from dict: [String: Any]) -> [[String]] {
        var rows: [[String]] = []
        for (key, value) in dict {
            let type = typeDescription(for: value)
            let stringValue = stringValue(for: value)
            rows.append([key, stringValue, type])
        }
        return rows
    }
    
    func typeDescription(for value: Any) -> String {
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
        case is [String: Any]: return "Dictionary"
        default: return String(describing: type(of: value))
        }
    }
    
    func stringValue(for value: Any) -> String {
        if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        }
        
        if let data = value as? Data {
            if let decodedObject = try? PropertyListSerialization.propertyList(from: data, format: nil) {
                return stringValue(for: decodedObject)
            }
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            
            if let stringValue = String(data: data, encoding: .utf8) {
                return stringValue
            }
            
            return "Data (\(data.count) bytes): \(data.map { String(format: "%02x", $0) }.prefix(50).joined())\(data.count > 50 ? "..." : "")"
        }
        
        if let string = value as? String {
            return string
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
