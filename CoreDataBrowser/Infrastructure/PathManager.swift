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
    private let fileManager = FileManager.default
    
    func reset() {
        simulatorPath = PathConstants.simulatorPath
        coreDataPath = PathConstants.libraryApplicationSupportPath
        swiftDataPath = PathConstants.libraryApplicationSupportPath
        userDefaultsPath = PathConstants.libraryPreferencesPath
    }
    
    func selectFolder(for binding: Binding<String>) {
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        
        // Set the initial directory to the current path
        let currentPath = binding.wrappedValue
        if !currentPath.isEmpty {
            let homeDir = fileManager.homeDirectoryForCurrentUser
            let fullPath = homeDir.appendingPathComponent(currentPath)
            
            // If path doesn't exist, go to parent directory
            fileManager.fileExists(atPath: fullPath.path()) ? (panel.directoryURL = fullPath) : (panel.directoryURL = fullPath.deletingLastPathComponent())
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            // Convert absolute path to relative path from home directory
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            url.path.hasPrefix(homeDir.path) ? (binding.wrappedValue = String(url.path.dropFirst(homeDir.path.count + 1))) : (binding.wrappedValue = url.path)
        }
    }
}
