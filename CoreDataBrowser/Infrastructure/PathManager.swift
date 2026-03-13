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
    func reset()
}

@MainActor
@Observable
class PathManagerImpl: PathManager {
    var isSheetPresented: Bool = false
    
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
    
    func reset() {
        simulatorPath = PathConstants.simulatorPath
        coreDataPath = PathConstants.libraryApplicationSupportPath
        swiftDataPath = PathConstants.libraryApplicationSupportPath
        userDefaultsPath = PathConstants.libraryPreferencesPath
    }
    
    func selectFolder(for binding: Binding<String>) {
        configureFolderPanel()
        setInitialDirectory(from: binding.wrappedValue)
        
        if panel.runModal() == .OK, let url = panel.url {
            // Convert absolute path to relative path from home directory
            binding.wrappedValue = convertToRelativePath(url)
        }
    }
    
    private func configureFolderPanel() {
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
    }
    
    private func setInitialDirectory(from path: String) {
        guard !path.isEmpty else { return }
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let fullPath = homeDir.appendingPathComponent(path)
        
        panel.directoryURL = fileManager.fileExists(atPath: fullPath.path())
        ? fullPath
        : fullPath.deletingLastPathComponent()
    }
    
    private func convertToRelativePath(_ url: URL) -> String {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        guard url.path.hasPrefix(homeDir.path) else {
            return url.path
        }
        return String(url.path.dropFirst(homeDir.path.count + 1))
    }
}
