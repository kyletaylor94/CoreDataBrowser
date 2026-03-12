//
//  SimulatorRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol SimulatorRepository {
    func getDeviceDirectories() throws -> [URL]
    func readDevicePlist(at url: URL) throws -> [String : Any]
}

class SimulatorRepositoryImpl: SimulatorRepository {
    private let fileManager = FileManager.default
    private let pathManager: PathManagerImpl
    
    init(pathManager: PathManagerImpl) {
        self.pathManager = pathManager
    }
    
    func getDeviceDirectories() throws -> [URL] {
        let basePath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(pathManager.simulatorPath)
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: nil
        ) else {
            throw SimulatorError.cannotAccessDevicesFolder
        }
        
        return contents.filter { url in
            let plistURL = url.appendingPathComponent(PathConstants.devicePlist)
            return fileManager.fileExists(atPath: plistURL.path)
        }
    }
    
    func readDevicePlist(at url: URL) throws -> [String: Any] {
        let plistURL = url.appendingPathComponent(PathConstants.devicePlist)
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        
        guard let dict = plist as? [String: Any] else {
            throw SimulatorError.cannotReadPlist(plistURL)
        }
        return dict
    }
}
