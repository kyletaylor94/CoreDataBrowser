//
//  DBUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

protocol DBUseCase {
    func executeCoreData(for device: SimulatorDevice) -> [DBDataTable]
    func executeSwiftData(for device: SimulatorDevice) -> [DBDataTable]
}

final class DBUseCaseImpl: DBUseCase {
    private let repository: DBRepository
    
    init(repository: DBRepository) {
        self.repository = repository
    }
    
    func executeCoreData(for device: SimulatorDevice) -> [DBDataTable] {
        fetchTables(for: device, fileExtension: DatabaseConstants.sqlite, shouldExecuteCheckpoint: false)
    }
    
    func executeSwiftData(for device: SimulatorDevice) -> [DBDataTable] {
        fetchTables(for: device, fileExtension: DatabaseConstants.store, shouldExecuteCheckpoint: true)
    }
        
    private func fetchTables(for device: SimulatorDevice, fileExtension: String, shouldExecuteCheckpoint: Bool) -> [DBDataTable] {
        var tables: [DBDataTable] = []
        let databaseFiles = repository.getDatabaseFiles(for: device, fileExtension: fileExtension)
        
        for file in databaseFiles {
            if shouldExecuteCheckpoint {
                repository.executeCheckpoint(at: file)
            }
            
            let allTableNames = repository.getTableNames(from: file)
            let filteredNames = filterTableNames(allTableNames)
            
            for tableName in filteredNames {
                let (columns, types, rows) = repository.getTableContent(from: file, table: tableName, limit: 50)
                let table = buildTable(
                    name: tableName,
                    columns: columns,
                    types: types,
                    rows: rows,
                    fileURL: file
                )
                
                if !tables.contains(table) {
                    tables.append(table)
                }
            }
        }
        
        return tables
    }
    
    private func filterTableNames(_ names: [String]) -> [String] {
        names
            .filter { !DatabaseConstants.excludedTables.contains($0.uppercased()) }
            .filter { !$0.lowercased().contains(DatabaseConstants.sqliteSequence) }
    }
    
    private func buildTable(name: String, columns: [String], types: [String], rows: [[String]], fileURL: URL) -> DBDataTable {
        let indicesToKeep = filterColumnIndices(columns: columns)
        return DBDataTable(
            name: name,
            columns: indicesToKeep.map { columns[$0] },
            rows: filteredRows(rows: rows, indicesToKeep: indicesToKeep),
            types: indicesToKeep.map { types[$0] },
            fileSize: repository.getFileSize(at: fileURL)
        )
    }
    
    private func filterColumnIndices(columns: [String]) -> [Int] {
        columns.enumerated()
            .filter { !DatabaseConstants.excludedColumns.contains($0.element.uppercased()) }
            .map { $0.offset }
    }
    
    private func filteredRows(rows: [[String]], indicesToKeep: [Int]) -> [[String]] {
        rows.map { row in
            indicesToKeep.compactMap { index in
                guard index < row.count else { return nil }
                return row[index]
            }
        }
    }
}
