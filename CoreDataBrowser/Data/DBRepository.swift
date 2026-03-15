//
//  DBRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

protocol DBRepository {
    func getDatabaseFiles(for device: SimulatorDevice, fileExtension: String) throws -> [URL]
    func getTableNames(from databaseURL: URL) -> [String]
    func getTableContent(from databaseURL: URL, table: String, limit: Int) -> (columns: [String], types: [String], rows: [[String]])
    func getFileSize(at url: URL) -> Int64
    func executeCheckpoint(at url: URL)
}

final class DBRepositoryImpl: DBRepository {
    private let fileManager: FileManager
    private let pathManager: PathManager
    private let sqliteExecutor: SQLiteExecutor
    
    init(fileManager: FileManager, pathManager: PathManager, sqliteExecutor: SQLiteExecutor) {
        self.fileManager = fileManager
        self.pathManager = pathManager
        self.sqliteExecutor = sqliteExecutor
    }
    
    /// Retrieves the database files for a given simulator device based on the specified file extension.
    /// - Parameters:
    /// - device: The `SimulatorDevice` for which to retrieve database files.
    /// - fileExtension: The file extension to filter database files
    /// - Returns: An array of `URL` objects representing the paths to the database files found for the specified simulator device. The method constructs the path to the simulator's apps directory, iterates through each app folder, and searches for database files in both the Documents and Library directories based on the provided file extension. If any issues arise while accessing the apps directory or reading its contents, a `DBError.cannotLoadApps` error is thrown with the relevant path information.
    func getDatabaseFiles(for device: SimulatorDevice, fileExtension: String) throws -> [URL] {
        let appsPath = device.path.appendingPathComponent(PathConstants.simulatorAppsPath)
        let appFolders: [URL]
        
        do {
            appFolders = try fileManager.contentsOfDirectory(at: appsPath, includingPropertiesForKeys: nil)
            let dataPath = fileExtension == DatabaseConstants.store ? pathManager.swiftDataPath : pathManager.coreDataPath
            var allFiles: [URL] = []
            
            for appFolder in appFolders {
                let appDataPath = appFolder.appendingPathComponent(DatabaseConstants.documents)
                let libraryPath = appFolder.appendingPathComponent(dataPath)
                let files = findDataStores(in: [appDataPath, libraryPath], withExtension: fileExtension)
                allFiles.append(contentsOf: files)
            }
            return allFiles
        } catch {
            throw DBError.cannotLoadApps(appsPath)
        }
    }
    
    /// Retrieves the names of all tables in the specified database.
    /// - Parameter databaseURL: The `URL` of the database file from which to fetch table names.
    /// - Returns: An array of `String` representing the names of the tables found in the database. The method uses the `sqliteExecutor` to execute a query that retrieves the table names from the database, ensuring that it can handle any SQLite database file provided as input.
    func getTableNames(from databaseURL: URL) -> [String] {
        return sqliteExecutor.fetchEntities(in: databaseURL)
    }
    
    /// Retrieves the content of a specified table from the database, including column names, data types, and rows of data.
    ///  - Parameters:
    ///   - databaseURL: The `URL` of the database file from which to fetch table content.
    ///   - table: The name of the table for which to retrieve content.
    ///   - limit: The maximum number of rows to retrieve from the table.
    ///   - Returns: A tuple containing three elements: an array of `String` representing the column names, an array of `String` representing the data types of each column, and a two-dimensional array of `String` representing the rows of data retrieved from the specified table. The method uses the `sqliteExecutor` to execute queries that fetch both the column information and the actual data rows, ensuring that it can handle any SQLite database file provided as input.
    func getTableContent(from databaseURL: URL, table: String, limit: Int) -> (columns: [String], types: [String], rows: [[String]]) {
        let (columns, types) = sqliteExecutor.fetchColumnsWithTypes(databaseURL: databaseURL, table: table)
        let rows = sqliteExecutor.fetchRows(at: databaseURL, query: DatabaseConstants.databaseContentQuery(table: table, limit: limit))
        return (columns, types, rows)
    }
    
    /// Retrieves the file size of the specified database file.
    /// - Parameter url: The `URL` of the database file for which to retrieve the file size.
    /// - Returns: An `Int64` representing the size of the file in bytes. The method uses the `fileManager` to access the file attributes and extract the file size, ensuring that it can handle any file provided as input and returns a default size of 0 if the file does not exist or if there is an error accessing its attributes.
    func getFileSize(at url: URL) -> Int64 {
        (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
    
    /// Executes a checkpoint on the specified database file to ensure that all changes are written to disk and the database is in a consistent state.
    /// - Parameter url: The `URL` of the database file on which to execute the checkpoint. The method uses the `sqliteExecutor` to execute a checkpoint query on the specified database file, ensuring that it can handle any SQLite database file provided as input and performs the necessary operations to maintain the integrity of the database.
    func executeCheckpoint(at url: URL) {
        _ = sqliteExecutor.execute(at: url, query: DatabaseConstants.walCheckpointQuery) { _ in }
    }
    
    /// Finds all data stores in the specified directories with the given file extension.
    /// - Parameters:
    ///  - directories: An array of `URL` objects representing the directories to search for data sores
    /// - ext: The file extension to filter data stores (e.g., "sqlite" or "store").
    /// - Returns: An array of `URL` objects representing the paths to the data stores found within the specified directories.
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
}
