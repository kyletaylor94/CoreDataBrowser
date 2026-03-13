//
//  UserDefaultsUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 13..
//

import Foundation

protocol UserDefaultsUseCase {
    func execute(for device: SimulatorDevice) async throws -> [DBDataTable]
}

final class UserDefaultsUseCaseImpl: UserDefaultsUseCase {
    private let repository: UserDefaultsRepository
    
    init(repository: UserDefaultsRepository) {
        self.repository = repository
    }
    
    func execute(for device: SimulatorDevice) async throws -> [DBDataTable] {
        let plistFiles = try await repository.loadPlistFiles(for: device)
        var tables: [DBDataTable] = []
        
        for file in plistFiles {
            guard let dict = try? repository.readPlistFile(at: file) else { continue }
            let table = createTable(from: file, dict: dict)
            
            if !tables.contains(where: { $0.name == table.name }) {
                tables.append(table)
            }
        }
        return tables
    }
    
    private func createTable(from file: URL, dict: [String: Any]) -> DBDataTable {
        let rows = extractRows(from: dict)
        let fileSize = repository.getFileSize(at: file)
        
        return DBDataTable(
            name: "UserDefaults - \(file.deletingPathExtension().lastPathComponent)",
            columns: ["Key", "Value", "Type"],
            rows: rows,
            types: ["", "", ""],
            fileSize: fileSize
        )
    }
    
    private func extractRows(from dict: [String: Any]) -> [[String]] {
        dict.map { key, value in
            [key, stringValue(for: value), typeDescription(for: value)]
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
        case is [String: Any]: return "Dictionary"
        default: return String(describing: type(of: value))
        }
    }
    
    private func stringValue(for value: Any) -> String {
        if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        }
        
        if let data = value as? Data {
            return formatDataValue(data)
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
    
    private func formatDataValue(_ data: Data) -> String {
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
}

