//
//  SearchRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol SearchRepository {
    func searchDevices(with text: String, in devices: [SimulatorDevice]) -> [SimulatorDevice]
    func searchTables(with text: String, in tables: [DBDataTable]) -> [DBDataTable]
    func searchColumns(with text: String, in tables: [DBDataTable]) -> [String]
    func searchRows(with text: String, in tables: [DBDataTable]) -> [String]
}

final class SearchRepositoryImpl: SearchRepository {
    
    /// Searches for devices whose names contain the given text (case-insensitive).
    /// - Parameters:
    ///   - text: The search text to look for in device names.
    ///   - devices: The list of devices to search through.
    ///   - Returns: An array of `SimulatorDevice` objects whose names contain the search text.
    ///   - Note: The search is case-insensitive, allowing for more flexible matching of device names.
    func searchDevices(with text: String, in devices: [SimulatorDevice]) -> [SimulatorDevice] {
        devices.filter { $0.name.lowercased().contains(text.lowercased()) }
    }
    
    /// Searches for tables that contain columns matching the given text (case-insensitive).
    /// - Parameters:
    ///  - text: The search text to look for in column names.
    ///  - tables: The list of tables to search through.
    ///  - Returns: An array of `DBDataTable` objects that contain columns matching the search text.
    ///  - Note: The search is case-insensitive, allowing for more flexible matching of column names within the tables.
    func searchTables(with text: String, in tables: [DBDataTable]) -> [DBDataTable] {
        tables.filter { table in
            table.columns.contains { column in
                column.lowercased().contains(text.lowercased())
            }
        }
    }
    
    /// Searches for column names that contain the given text (case-insensitive) across all tables.
    /// - Parameters:
    ///  - text: The search text to look for in column names.
    ///  - tables: The list of tables to search through.
    ///  - Returns: An array of column names that contain the search text.
    ///  - Note: The search is case-insensitive, allowing for more flexible matching of column names across all tables.
    func searchColumns(with text: String, in tables: [DBDataTable]) -> [String] {
        let columns = tables.flatMap { $0.columns }
        return columns.filter { $0.lowercased().contains(text.lowercased()) }
    }
    
    
    /// Searches for cell values that contain the given text (case-insensitive) across all rows in all tables.
    /// - Parameters:
    /// - text: The search text to look for in cell values.
    /// - tables: The list of tables to search through.
    /// - Returns: An array of cell values that contain the search text.
    func searchRows(with text: String, in tables: [DBDataTable]) -> [String] {
        let rows = tables.flatMap { $0.rows }
        let filteredRows = rows.filter { row in
            row .contains { cell in
                cell.lowercased().contains(text.lowercased())
            }
        }
        return filteredRows.flatMap { $0 }
    }
}
