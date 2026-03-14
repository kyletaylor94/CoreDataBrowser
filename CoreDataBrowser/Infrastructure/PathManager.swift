//
//  PathManager.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import Observation
import SwiftUI

protocol PathManager {
    var simulatorPath: String { get set }
    var coreDataPath: String { get set }
    var swiftDataPath: String { get set }
    var userDefaultsPath: String { get set }
    func selectFolder(for binding: Binding<String>)
    func resetPaths()
}

@MainActor
@Observable
class PathManagerImpl: PathManager {
    var isSheetPresented: Bool = false
    
    /// Paths are stored as relative to the user's home directory for better readability and portability. When retrieving, they are converted back to absolute paths.
    var simulatorPath: String = UserDefaults.standard.string(forKey: "simulatorPath") ?? PathConstants.simulatorPath {
        didSet {
            UserDefaults.standard.set(simulatorPath, forKey: "simulatorPath")
        }
    }
    
    var coreDataPath: String = UserDefaults.standard.string(forKey: "coreDataPath") ?? PathConstants.libraryApplicationSupportPath {
        didSet {
            UserDefaults.standard.set(coreDataPath, forKey: "coreDataPath")
        }
    }
    
    var swiftDataPath: String = UserDefaults.standard.string(forKey: "swiftDataPath") ?? PathConstants.libraryApplicationSupportPath {
        didSet {
            UserDefaults.standard.set(swiftDataPath, forKey: "swiftDataPath")
        }
    }
    
    var userDefaultsPath: String = UserDefaults.standard.string(forKey: "userDefaultsPath") ?? PathConstants.libraryPreferencesPath {
        didSet {
            UserDefaults.standard.set(userDefaultsPath, forKey: "userDefaultsPath")
        }
    }
    
    private let panel = NSOpenPanel()
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    /// Resets all paths to their default values.
    func resetPaths() {
        simulatorPath = PathConstants.simulatorPath
        coreDataPath = PathConstants.libraryApplicationSupportPath
        swiftDataPath = PathConstants.libraryApplicationSupportPath
        userDefaultsPath = PathConstants.libraryPreferencesPath
    }
    
    /// Presents a folder selection dialog and updates the binding with the selected folder's relative path.
    /// - Parameter binding: A binding to the path string that should be updated with the selected folder's relative path.
    /// The method configures the NSOpenPanel to allow only folder selection, sets the initial directory based on the current value of the binding, and upon successful selection, converts the absolute path to a relative path from the user's home directory before updating the binding.
    func selectFolder(for binding: Binding<String>) {
        configureFolderPanel()
        setInitialDirectory(from: binding.wrappedValue)
        
        if panel.runModal() == .OK, let url = panel.url {
            binding.wrappedValue = convertToRelativePath(url)
        }
    }
    
    /// Configures the NSOpenPanel to allow only folder selection, disallowing file selection and multiple selections.
    private func configureFolderPanel() {
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
    }
    
    /// Sets the initial directory of the NSOpenPanel based on the provided path. If the path is valid, it will be used as the initial directory; otherwise, the panel will default to the user's home directory.
    /// - Parameter path: The relative path from the user's home directory to set as the initial directory for the NSOpenPanel.
    private func setInitialDirectory(from path: String) {
        guard !path.isEmpty else { return }
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let fullPath = homeDir.appendingPathComponent(path)
        
        panel.directoryURL = fileManager.fileExists(atPath: fullPath.path())
        ? fullPath
        : fullPath.deletingLastPathComponent()
    }
    
    /// Converts an absolute URL to a relative path from the user's home directory. If the URL does not reside within the home directory, it returns the absolute path.
    /// - Parameter url: The absolute URL to convert.
    private func convertToRelativePath(_ url: URL) -> String {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        guard url.path.hasPrefix(homeDir.path) else {
            return url.path
        }
        return String(url.path.dropFirst(homeDir.path.count + 1))
    }
}
