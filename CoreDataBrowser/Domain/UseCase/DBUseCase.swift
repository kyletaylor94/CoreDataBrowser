//
//  DBUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

protocol DBUseCase {
    func executeCoreData(for device: SimulatorDevice) throws -> [DBDataTable]
    func executeSwiftData(for device: SimulatorDevice) throws -> [DBDataTable]
    func fetchRelationships(for tables: [DBDataTable]) -> [String: [DBForeignKey]]
}

final class DBUseCaseImpl: DBUseCase {
    private let repository: DBRepository
    
    init(repository: DBRepository) {
        self.repository = repository
    }
    
    /// Executes the fetching of Core Data database tables for a given simulator device by invoking the `fetchTables` method with the appropriate parameters, including the file extension for SQLite databases and the flag to skip checkpoint execution, which is not necessary for Core Data databases.
    /// - Parameter device: The `SimulatorDevice` for which to fetch the Core Data database
    /// - Returns: An array of `DBDataTable` instances representing the fetched Core Data database tables, with filtered columns and rows based on predefined exclusion criteria, providing a structured representation of the relevant data from the Core Data databases.
    /// - Throws: An error if there are issues fetching the database tables, such as problems accessing the database files or executing checkpoints.
    func executeCoreData(for device: SimulatorDevice) throws -> [DBDataTable] {
        try fetchTables(for: device, fileExtension: DatabaseConstants.sqlite, shouldExecuteCheckpoint: false)
    }
    
    /// Executes the fetching of SwiftData database tables for a given simulator device by invoking the `fetchTables` method with the appropriate parameters, including the file extension for SwiftData databases and the flag to execute checkpoints, which is necessary to ensure data consistency when working with SwiftData databases.
    /// - Parameter device: The `SimulatorDevice` for which to fetch the SwiftData database
    /// - Returns: An array of `DBDataTable` instances representing the fetched SwiftData database tables, with filtered columns and rows based on predefined exclusion criteria, providing a structured representation of the relevant data from the SwiftData databases.
    /// - Throws: An error if there are issues fetching the database tables, such as problems accessing the database files or executing checkpoints.
    func executeSwiftData(for device: SimulatorDevice) throws -> [DBDataTable] {
       try fetchTables(for: device, fileExtension: DatabaseConstants.store, shouldExecuteCheckpoint: true)
    }
    
    /// Fetches the foreign key relationships for each of the given entity tables. This first tries the
    /// real SQL foreign key constraints declared on each table (via `PRAGMA foreign_key_list`), which is
    /// the most accurate source when present. However, not every Core Data SQLite store actually declares
    /// real `FOREIGN KEY` constraints for its relationships (this depends on the store's configuration),
    /// so for any table where none were found, this falls back to inferring relationships by convention:
    /// an integer-affinity column whose name matches (or is a prefix/suffix of) another entity's table
    /// name is treated as a to-one relationship pointing at that entity (e.g. a `BASKET` column on
    /// `FRUITENTITY` referencing `BASKETENTITY`).
    /// - Parameter tables: The `DBDataTable` instances (typically `coreDataTables`) to inspect for relationships.
    /// - Returns: A dictionary mapping each table's name to the list of `DBForeignKey` found on it.
    func fetchRelationships(for tables: [DBDataTable]) -> [String: [DBForeignKey]] {
        var result: [String: [DBForeignKey]] = [:]
        
        for table in tables {
            guard let fileURL = table.fileURL else { continue }
            let foreignKeys = repository.getForeignKeys(from: fileURL, table: table.name)
            if !foreignKeys.isEmpty {
                result[table.name] = foreignKeys
            }
        }
        
        let candidateTableNames = tables.map(\.name)
        for table in tables where result[table.name] == nil {
            let inferred = inferRelationships(for: table, candidateTableNames: candidateTableNames)
            if !inferred.isEmpty {
                result[table.name] = inferred
            }
        }
        return result
    }
    
    /// Infers to-one relationships for a table by matching its integer-affinity columns against the
    /// names of the other known entity tables, used as a fallback when no real SQL foreign key
    /// constraints are declared on the underlying SQLite store.
    /// - Parameters:
    ///  - table: The table whose columns should be inspected.
    ///  - candidateTableNames: The full set of known entity table names to match columns against.
    /// - Returns: An array of inferred `DBForeignKey` for the given table.
    private func inferRelationships(for table: DBDataTable, candidateTableNames: [String]) -> [DBForeignKey] {
        var inferred: [DBForeignKey] = []
        
        for (column, type) in zip(table.columns, table.types) {
            guard type.uppercased().contains("INT"),
                  !DatabaseConstants.excludedColumns.contains(column.uppercased()) else {
                continue
            }
            
            let cleanColumn = FormattingHelper.removeZPrefix(from: column).uppercased()
            
            guard let matchedTable = candidateTableNames.first(where: { candidate in
                guard candidate != table.name else { return false }
                let cleanCandidate = FormattingHelper.removeZPrefix(from: candidate).uppercased()
                return cleanCandidate == cleanColumn
                    || cleanCandidate.hasPrefix(cleanColumn)
                    || cleanColumn.hasPrefix(cleanCandidate)
            }) else {
                continue
            }
            
            inferred.append(
                DBForeignKey(
                    column: column,
                    destinationTable: matchedTable,
                    destinationColumn: "Z_PK"
                )
            )
        }
        return inferred
    }
    
    /// Fetches database tables for a given simulator device based on the specified file extension and checkpoint execution flag. The method retrieves database files, optionally executes checkpoints, and constructs `DBDataTable` instances while filtering out unwanted tables and columns based on predefined criteria.
    /// - Parameters:
    /// - device: The `SimulatorDevice` for which to fetch the database tables.
    /// - fileExtension: The file extension to filter the database files.
    /// - shouldExecuteCheckpoint: A boolean flag indicating whether to execute a checkpoint on the database files before fetching the tables, which is necessary for SwiftData databases to ensure data consistency.
    /// - Returns: An array of `DBDataTable` instances representing the fetched database tables, with filtered columns and rows based on predefined exclusion criteria, providing a structured representation of the relevant data
    private func fetchTables(for device: SimulatorDevice, fileExtension: String, shouldExecuteCheckpoint: Bool) throws -> [DBDataTable] {
        var tables: [DBDataTable] = []
        let databaseFiles = try repository.getDatabaseFiles(for: device, fileExtension: fileExtension)
        
        for file in databaseFiles {
            if shouldExecuteCheckpoint {
                repository.executeCheckpoint(at: file)
            }
            
            let allTableNames = repository.getTableNames(from: file)
            let filteredNames = filterTableNames(allTableNames)
            
            for tableName in filteredNames {
                let (columns, types, rows, nullability) = repository.getTableContent(from: file, table: tableName, limit: 50)
                let table = buildTable(
                    name: tableName,
                    columns: columns,
                    types: types,
                    rows: rows,
                    nullability: nullability,
                    fileURL: file
                )
                
                if !tables.contains(table) {
                    tables.append(table)
                }
            }
        }
        
        return tables
    }
    
    /// Filters out unwanted table names based on predefined exclusion criteria, such as specific table names or patterns that are commonly used for internal SQLite management.
    /// - Parameter names: An array of table names to be filtered.
    /// - Returns: An array of table names that have been filtered to exclude unwanted entries, ensuring that only relevant tables are included in the results.
    private func filterTableNames(_ names: [String]) -> [String] {
        names
            .filter { !DatabaseConstants.excludedTables.contains($0.uppercased()) }
            .filter { !$0.lowercased().contains(DatabaseConstants.sqliteSequence) }
    }
    
    /// Builds a `DBDataTable` instance by filtering out unwanted columns and their corresponding types and rows based on predefined exclusion criteria, ensuring that only relevant data is included in the resulting table.
    /// - Parameters:
    ///  - name: The name of the table.
    ///  - columns: An array of column names from the database table.
    ///  - types: An array of data types corresponding to each column in the database table
    ///  - rows: A two-dimensional array representing the rows of data from the database table, where each inner array corresponds to a single row of data.
    ///  - fileURL: The URL of the database file from which the table was fetched
    ///  - Returns: A `DBDataTable` instance containing the filtered columns, types, and rows, along with the file size of the database file, providing a structured representation of the table's content while excluding irrelevant data.
    private func buildTable(name: String, columns: [String], types: [String], rows: [[String]], nullability: [Bool], fileURL: URL) -> DBDataTable {
        let indicesToKeep = filterColumnIndices(columns: columns)
        return DBDataTable(
            name: name,
            columns: indicesToKeep.map { columns[$0] },
            rows: filteredRows(rows: rows, indicesToKeep: indicesToKeep),
            types: indicesToKeep.map { types[$0] },
            fileSize: repository.getFileSize(at: fileURL),
            fileURL: fileURL,
            isOptional: indicesToKeep.map { $0 < nullability.count ? nullability[$0] : false }
        )
    }
    
    /// Filters out unwanted column indices based on predefined exclusion criteria, such as specific column names that are commonly used for internal SQLite management or metadata.
    /// - Parameter columns: An array of column names to be filtered.
    /// - Returns: An array of integer indices representing the positions of the columns that have been filtered to exclude unwanted entries, ensuring that only relevant columns are included in the results when building the `DBDataTable` instances.
    private func filterColumnIndices(columns: [String]) -> [Int] {
        columns.enumerated()
            .filter { !DatabaseConstants.excludedColumns.contains($0.element.uppercased()) }
            .map { $0.offset }
    }
    
    /// Filters the rows of data based on the specified indices to keep, ensuring that only the relevant columns are included in the resulting rows while excluding unwanted data.
    /// - Parameters:
    ///  - rows: A two-dimensional array representing the rows of data from the database table
    ///  - indicesToKeep: An array of integer indices representing the positions of the columns that should be included in the resulting rows, based on predefined exclusion criteria.
    ///  - Returns: A two-dimensional array of strings representing the filtered rows of data, where each inner array corresponds to a single row of data that includes only the relevant columns based on the specified indices to keep.
    ///  - Note: The method uses `compactMap` to ensure that only valid indices are included in the resulting rows, preventing any out-of-bounds errors when accessing the columns of each row.
    private func filteredRows(rows: [[String]], indicesToKeep: [Int]) -> [[String]] {
        rows.map { row in
            indicesToKeep.compactMap { index in
                guard index < row.count else { return nil }
                return row[index]
            }
        }
    }
}
