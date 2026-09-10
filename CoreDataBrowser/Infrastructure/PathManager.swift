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
    /// Presents a folder selection dialog specifically for the Simulator "Devices" path, also (re)creating and persisting the security-scoped bookmark for the selected folder.
    func selectSimulatorFolder(for binding: Binding<String>)
    func resetPaths()
    /// Resolves the user-granted, security-scoped root URL for the Simulator "Devices" folder.
    /// Prompts the user with an `NSOpenPanel` to grant access if no valid bookmark exists yet.
    func resolveSimulatorRootURL() throws -> URL
    func invalidateSimulatorAccess()
}

@MainActor
@Observable
class PathManagerImpl: PathManager {
    var isSheetPresented: Bool = false
    
    /// Paths are stored as relative to the user's home directory for better readability and portability. When retrieving, they are converted back to absolute paths.
    var simulatorPath: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.simulatorPath) ?? PathConstants.simulatorPath {
        didSet {
            UserDefaults.standard.set(simulatorPath, forKey: UserDefaultsKeys.simulatorPath)
        }
    }
    
    var coreDataPath: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.coreDataPath) ?? PathConstants.libraryApplicationSupportPath {
        didSet {
            UserDefaults.standard.set(coreDataPath, forKey: UserDefaultsKeys.coreDataPath)
        }
    }
    
    var swiftDataPath: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.swiftDataPath) ?? PathConstants.libraryApplicationSupportPath {
        didSet {
            UserDefaults.standard.set(swiftDataPath, forKey: UserDefaultsKeys.swiftDataPath)
        }
    }
    
    var userDefaultsPath: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.userDefaultsPath) ?? PathConstants.libraryPreferencesPath {
        didSet {
            UserDefaults.standard.set(userDefaultsPath, forKey: UserDefaultsKeys.userDefaultsPath)
        }
    }
    
    private let panel = NSOpenPanel()
    private let fileManager: FileManager
    private let simulatorBookmarkKey = "simulatorRootBookmarkData"
    /// The currently active, security-scoped URL for the Simulator "Devices" folder, kept alive for the app's session so repeated file access doesn't need to re-resolve the bookmark every time.
    private var accessedSimulatorRootURL: URL?
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func invalidateSimulatorAccess() {
        clearSimulatorBookmark()
    }
    
    /// Resets all paths to their default values.
    func resetPaths() {
        simulatorPath = PathConstants.simulatorPath
        coreDataPath = PathConstants.libraryApplicationSupportPath
        swiftDataPath = PathConstants.libraryApplicationSupportPath
        userDefaultsPath = PathConstants.libraryPreferencesPath
        clearSimulatorBookmark()
    }
    
    /// Resolves the security-scoped root URL granting access to the Simulator "Devices" folder.
    /// - If a valid, previously-granted bookmark exists (persisted via `com.apple.security.files.bookmarks.app-scope`), it is resolved and reused automatically, with no user interaction required.
    /// - Otherwise (e.g. on first launch, or if the user revoked access), an `NSOpenPanel` is presented so the user can grant access, and the resulting security-scoped bookmark is persisted for future launches.
    /// - Throws: `SimulatorError.accessNotGranted` if the user cancels the folder picker or access cannot be established.
    func resolveSimulatorRootURL() throws -> URL {
        if let cached = accessedSimulatorRootURL {
            return cached
        }
        
        if let data = UserDefaults.standard.data(forKey: simulatorBookmarkKey) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale),
               url.startAccessingSecurityScopedResource() {
                if isStale {
                    try? persistSimulatorBookmark(for: url)
                }
                accessedSimulatorRootURL = url
                return url
            }
            // The persisted bookmark is no longer valid (e.g. folder moved/deleted); discard it and re-prompt.
            UserDefaults.standard.removeObject(forKey: simulatorBookmarkKey)
        }
        
        return try promptUserForSimulatorFolder()
    }
    
    /// Presents an `NSOpenPanel` asking the user to grant access to their Simulator "Devices" folder, defaulting the initial directory to the real home directory's `Library/Developer/CoreSimulator/Devices` path.
    private func promptUserForSimulatorFolder() throws -> URL {
        let accessPanel = NSOpenPanel()
        accessPanel.canChooseFiles = false
        accessPanel.canChooseDirectories = true
        accessPanel.allowsMultipleSelection = false
        accessPanel.canCreateDirectories = false
        accessPanel.message = "CoreDataBrowser needs access to your Simulator devices to browse their app data. Select the top-level “Devices” folder itself — do not open it and select one of the simulator folders inside."
        accessPanel.prompt = "Grant Access"
        accessPanel.directoryURL = fileManager.realHomeDirectoryForCurrentUser
            .appendingPathComponent(simulatorPath)
        
        // Make sure the app (and its window) is frontmost before presenting the modal panel.
        // If this runs too early (e.g. during initial launch before the window is key),
        // `runModal()` can otherwise return immediately without ever showing the panel.
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.isVisible })?.makeKeyAndOrderFront(nil)
        
        guard accessPanel.runModal() == .OK, let url = accessPanel.url else {
            throw SimulatorError.accessNotGranted
        }
        
        try persistSimulatorBookmark(for: url)
        guard url.startAccessingSecurityScopedResource() else {
            throw SimulatorError.accessNotGranted
        }
        accessedSimulatorRootURL = url
        return url
    }
    
    /// Creates and persists a security-scoped, app-scoped bookmark for the given URL so access can be restored automatically on future launches without prompting the user again.
    private func persistSimulatorBookmark(for url: URL) throws {
        let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(data, forKey: simulatorBookmarkKey)
    }
    
    /// Stops accessing and discards any previously granted security-scoped bookmark for the Simulator "Devices" folder, forcing the user to be prompted again on next access.
    private func clearSimulatorBookmark() {
        accessedSimulatorRootURL?.stopAccessingSecurityScopedResource()
        accessedSimulatorRootURL = nil
        UserDefaults.standard.removeObject(forKey: simulatorBookmarkKey)
    }
    
    /// Presents a folder selection dialog and updates the binding with the selected folder's relative path.
    /// - Parameter binding: A binding to the path string that should be updated with the selected folder's relative path.
    /// The method configures the NSOpenPanel to allow only folder selection, sets the initial directory based on the current value of the binding, and upon successful selection, converts the absolute path to a relative path from the user's home directory before updating the binding.
    /// - Note: If the binding refers to the Simulator path, this also (re)creates and persists the security-scoped bookmark for the newly selected folder, replacing any previously granted access.
    func selectFolder(for binding: Binding<String>) {
        selectFolder(for: binding, updatesSimulatorBookmark: false)
    }
    
    /// Presents a folder selection dialog specifically for the Simulator "Devices" path. In addition to updating the binding, this (re)creates and persists the security-scoped bookmark for the newly selected folder, replacing any previously granted access.
    /// - Parameter binding: A binding to the Simulator path string.
    func selectSimulatorFolder(for binding: Binding<String>) {
        selectFolder(for: binding, updatesSimulatorBookmark: true)
    }
    
    private func selectFolder(for binding: Binding<String>, updatesSimulatorBookmark: Bool) {
        configureFolderPanel()
        setInitialDirectory(from: binding.wrappedValue)
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        binding.wrappedValue = convertToRelativePath(url)
        
        guard updatesSimulatorBookmark else { return }
        clearSimulatorBookmark()
        if let bookmarkData = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(bookmarkData, forKey: simulatorBookmarkKey)
            accessedSimulatorRootURL = url.startAccessingSecurityScopedResource() ? url : nil
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
        let homeDir = fileManager.realHomeDirectoryForCurrentUser
        let fullPath = homeDir.appendingPathComponent(path)
        
        panel.directoryURL = fileManager.fileExists(atPath: fullPath.path())
        ? fullPath
        : fullPath.deletingLastPathComponent()
    }
    
    /// Converts an absolute URL to a relative path from the user's home directory. If the URL does not reside within the home directory, it returns the absolute path.
    /// - Parameter url: The absolute URL to convert.
    private func convertToRelativePath(_ url: URL) -> String {
        let homeDir = fileManager.realHomeDirectoryForCurrentUser
        guard url.path.hasPrefix(homeDir.path) else {
            return url.path
        }
        return String(url.path.dropFirst(homeDir.path.count + 1))
    }
}
