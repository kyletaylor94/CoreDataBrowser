//
//  SimulatorRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol UserDefaultsRepository {
    func loadPlistFiles(for device: SimulatorDevice) async throws -> [URL]
    func readPlistFile(at url: URL) throws -> [String: Any]
    func getFileSize(at url: URL) -> Int64
}

final class UserDefaultsRepositoryImpl: UserDefaultsRepository {
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func loadPlistFiles(for device: SimulatorDevice) async throws -> [URL] {
        let preferencesPath = device.path.appendingPathComponent(PathConstants.simulatorAppsPath)
        
        guard let appFolders = try? fileManager.contentsOfDirectory(at: preferencesPath, includingPropertiesForKeys: nil) else {
            throw UserDefaultsError.cannotLoadApps(preferencesPath)
        }
        
        var plistFiles: [URL] = []
        
        for appFolder in appFolders {
            let libraryPath = appFolder.appendingPathComponent(PathConstants.libraryPreferencesPath)
            guard fileManager.fileExists(atPath: libraryPath.path) else { continue }
            
            guard let contents = try? fileManager.contentsOfDirectory(at: libraryPath, includingPropertiesForKeys: nil) else {
                throw UserDefaultsError.readError(libraryPath)
            }
            
            let validPlistFiles = contents.filter {
                $0.pathExtension == PathConstants.plistExtension &&
                !$0.lastPathComponent.hasPrefix("com.apple.")
            }
            
            plistFiles.append(contentsOf: validPlistFiles)
        }
        
        return plistFiles
    }
    
    func readPlistFile(at url: URL) throws -> [String: Any] {
        guard let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            throw UserDefaultsError.invalidFormat(url)
        }
        return dict
    }
    
    func getFileSize(at url: URL) -> Int64 {
        (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
}
