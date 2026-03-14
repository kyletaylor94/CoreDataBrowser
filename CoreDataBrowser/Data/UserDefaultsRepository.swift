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
    
    /// Loads all valid plist files from the given simulator device's app directories.
    /// - Parameter device: The simulator device to load plist files from.
    /// - Returns: An array of URLs pointing to the valid plist files found.
    /// - Throws: `UserDefaultsError` if there are issues accessing the directories or reading the contents.
    /// - Note: The method filters out plist files that are not relevant (e.g., those starting with "com.apple.") to ensure only user-related preferences are loaded.
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
    
    /// Reads the contents of a plist file at the given URL and returns it as a dictionary.
    /// - Parameter url: The URL of the plist file to read.
    /// - Returns: A dictionary containing the contents of the plist file.
    /// - Throws: `UserDefaultsError` if the file cannot be read or if the  file format is invalid (i.e., not a dictionary).
    /// - Note: The method uses `NSDictionary` to read the plist file, which allows for robust handling of various plist formats. It ensures that the returned data is a dictionary, which is the expected format for UserDefaults plist files.
    func readPlistFile(at url: URL) throws -> [String: Any] {
        guard let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            throw UserDefaultsError.invalidFormat(url)
        }
        return dict
    }
    
    /// Retrieves the file size of the plist file at the specified URL.
    /// - Parameter url: The URL of the plist file to check.
    /// - Returns: The size of the file in bytes, or 0 if the file cannot be accessed or does not exist.
    /// - Note: The method uses `FileManager` to access the file attributes and extract the file size. It handles any errors gracefully by returning 0 if the file cannot be accessed or if the size attribute is not available.
    func getFileSize(at url: URL) -> Int64 {
        (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
}
