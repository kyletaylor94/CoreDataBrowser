//
//  PathManager.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
class PathManager {
    var isSheetPresented: Bool = false
    
    var simulatorPath: String {
          didSet {
              UserDefaults.standard.set(simulatorPath, forKey: "simulatorPath")
          }
      }
      
      var coreDataPath: String {
          didSet {
              UserDefaults.standard.set(coreDataPath, forKey: "coreDataPath")
          }
      }
      
      var swiftDataPath: String {
          didSet {
              UserDefaults.standard.set(swiftDataPath, forKey: "swiftDataPath")
          }
      }
      
      var userDefaultsPath: String {
          didSet {
              UserDefaults.standard.set(userDefaultsPath, forKey: "userDefaultsPath")
          }
      }
      
      init() {
          self.simulatorPath = UserDefaults.standard.string(forKey: "simulatorPath") ?? Constants.SIMULATOR_PATH
          self.coreDataPath = UserDefaults.standard.string(forKey: "coreDataPath") ?? Constants.LIBRARY_APPLICATIONSUPPORT_PATH
          self.swiftDataPath = UserDefaults.standard.string(forKey: "swiftDataPath") ?? Constants.LIBRARY_APPLICATIONSUPPORT_PATH
          self.userDefaultsPath = UserDefaults.standard.string(forKey: "userDefaultsPath") ?? Constants.LIBRARY_PREFENCES_PATH
      }
        
    func reset() {
        simulatorPath = Constants.SIMULATOR_PATH
        coreDataPath = Constants.LIBRARY_APPLICATIONSUPPORT_PATH
        swiftDataPath = Constants.LIBRARY_APPLICATIONSUPPORT_PATH
        userDefaultsPath = Constants.LIBRARY_PREFENCES_PATH
    }
    
     func selectFolder(for binding: Binding<String>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        
        // Set the initial directory to the current path
        let currentPath = binding.wrappedValue
        if !currentPath.isEmpty {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let fullPath = homeDir.appendingPathComponent(currentPath)
            
            if FileManager.default.fileExists(atPath: fullPath.path) {
                panel.directoryURL = fullPath
            } else {
                // If path doesn't exist, go to parent directory
                panel.directoryURL = fullPath.deletingLastPathComponent()
            }
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            // Convert absolute path to relative path from home directory
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            if url.path.hasPrefix(homeDir.path) {
                let relativePath = String(url.path.dropFirst(homeDir.path.count + 1))
                binding.wrappedValue = relativePath
            } else {
                binding.wrappedValue = url.path
            }
        }
    }
}
