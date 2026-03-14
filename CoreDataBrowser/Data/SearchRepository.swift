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
    func searchDevices(with text: String, in devices: [SimulatorDevice]) -> [SimulatorDevice] {
        devices.filter { $0.name.lowercased().contains(text.lowercased()) }
    }
    
    func searchTables(with text: String, in tables: [DBDataTable]) -> [DBDataTable] {
        tables.filter { table in
            table.columns.contains { column in
                column.lowercased().contains(text.lowercased())
            }
        }
    }
    
    func searchColumns(with text: String, in tables: [DBDataTable]) -> [String] {
        let columns = tables.flatMap { $0.columns }
        return columns.filter { $0.lowercased().contains(text.lowercased()) }
    }
    
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
