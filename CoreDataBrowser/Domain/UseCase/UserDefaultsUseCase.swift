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
    
    /// Executes the use case to fetch and parse UserDefaults data for a given simulator device.
    /// - Parameter device: The `SimulatorDevice` for which to fetch UserDefaults data.
    /// - Returns: An array of `DBDataTable` containing the parsed UserDefaults data
    /// - Throws: `UserDefaultsError` if there are issues accessing the UserDefaults files or parsing their contents.
    /// - Note: The method retrieves the UserDefaults files for the specified device, reads their contents, and creates `DBDataTable` instances for each file. It handles errors gracefully by throwing appropriate exceptions when issues arise during file access or data parsing.
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
    
    /// Creates a `DBDataTable` from a given plist file and its contents.
    /// - Parameters:
    ///  - file: The `URL` of the plist file containing UserDefaults data.
    ///  - dict: A dictionary representing the key
    /// - Returns: A `DBDataTable` instance containing the parsed UserDefaults data from the specified file.
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
    
    /// Extracts rows of data from a given dictionary, where each row represents a key-value pair along with its type description.
    /// - Parameter dict: A dictionary containing the key-value pairs to be extracted.
    /// - Returns: An array of rows, where each row is an array of strings representing the key, value, and type description of each entry in the dictionary.
    private func extractRows(from dict: [String: Any]) -> [[String]] {
        dict.map { key, value in
            [key, stringValue(for: value), typeDescription(for: value)]
        }
    }
    
    /// Determines the type description for a given value, returning a string representation of the value's type.
    /// - Parameter value: The value for which to determine the type description.
    /// - Returns: A string representing the type of the value, such as "String", "Int", "Bool", "Array", "Dictionary", etc.
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
    
    /// Converts a given value to its string representation, handling various types such as booleans, data, strings, numbers, arrays, and dictionaries.
    /// - Parameter value: The value to be converted to a string representation.
    /// - Returns: A string representing the value, formatted appropriately based on its type. For example, booleans are represented as "true" or "false", data is formatted as a hex string or decoded if possible, and arrays/dictionaries are represented in a readable format.
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
    
    
    /// Formats a `Data` object into a readable string representation. The method attempts to decode the data as a property list or JSON, and if those attempts fail, it returns a hex string representation of the data.
    /// - Parameter data: The `Data` object to be formatted.
    /// - Returns: A string representing the formatted data. If the data can be decoded as a property list or JSON, it returns the decoded string; otherwise, it returns a hex string representation of the data with a byte count.
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
