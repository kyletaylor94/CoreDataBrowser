//
//  DBRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

protocol DBRepository {
    func getDatabaseFiles(for device: SimulatorDevice, fileExtension: String) -> [URL]
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
    
    func getDatabaseFiles(for device: SimulatorDevice, fileExtension: String) -> [URL] {
        let appsPath = device.path.appendingPathComponent(PathConstants.simulatorAppsPath)
        guard let appFolders = try? fileManager.contentsOfDirectory(at: appsPath, includingPropertiesForKeys: nil) else {
            return []
        }
        
        let dataPath = fileExtension == DatabaseConstants.store ? pathManager.swiftDataPath : pathManager.coreDataPath
        var allFiles: [URL] = []
        
        for appFolder in appFolders {
            let appDataPath = appFolder.appendingPathComponent(DatabaseConstants.documents)
            let libraryPath = appFolder.appendingPathComponent(dataPath)
            let files = findDataStores(in: [appDataPath, libraryPath], withExtension: fileExtension)
            allFiles.append(contentsOf: files)
        }
        
        return allFiles
    }
    
    func getTableNames(from databaseURL: URL) -> [String] {
        return sqliteExecutor.fetchEntities(in: databaseURL)
    }
    
    func getTableContent(from databaseURL: URL, table: String, limit: Int) -> (columns: [String], types: [String], rows: [[String]]) {
        let (columns, types) = sqliteExecutor.fetchColumnsWithTypes(databaseURL: databaseURL, table: table)
        let rows = sqliteExecutor.fetchRows(at: databaseURL, query: DatabaseConstants.databaseContentQuery(table: table, limit: limit))
        return (columns, types, rows)
    }
    
    func getFileSize(at url: URL) -> Int64 {
        (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
    
    func executeCheckpoint(at url: URL) {
        _ = sqliteExecutor.execute(at: url, query: DatabaseConstants.walCheckpointQuery) { _ in }
    }
    
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
