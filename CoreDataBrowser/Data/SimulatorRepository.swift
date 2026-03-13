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
    private let fileManager: FileManager
    private let pathManager: PathManager
    
    init(fileManager: FileManager, pathManager: PathManager) {
        self.fileManager = fileManager
        self.pathManager = pathManager
    }
    
    func getDeviceDirectories() throws -> [URL] {
        let basePath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(pathManager.simulatorPath)
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: basePath,
                includingPropertiesForKeys: nil
            )
            
            return contents.filter { url in
                let plistURL = url.appendingPathComponent(PathConstants.devicePlist)
                return fileManager.fileExists(atPath: plistURL.path)
            }
        } catch {
            throw SimulatorError.cannotAccessDevicesFolder(underlyingError: error)
        }
    }
    
    func readDevicePlist(at url: URL) throws -> [String: Any] {
        let plistURL = url.appendingPathComponent(PathConstants.devicePlist)
        do {
            let data = try Data(contentsOf: plistURL)
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
            
            guard let dict = plist as? [String: Any] else {
                throw SimulatorError.invalidPlistFormat
            }
            return dict
        } catch let error as SimulatorError {
            throw error
        } catch {
            throw SimulatorError.cannotReadPlist(underlyingError: error)
        }
    }
}
