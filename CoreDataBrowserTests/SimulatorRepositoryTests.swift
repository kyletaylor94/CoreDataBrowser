//
//  SimulatorRepositoryTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 15..
//

import Testing
import Foundation
import SwiftUI
@testable import CoreDataBrowser

struct SimulatorRepositoryTests {
    
    @Test("getDevicesDirectories returns valid directories")
    func GetDevicesDirectoriesReturnsValidDirectories() async throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        let repository = await SimulatorRepositoryImpl(fileManager: mockFileManager, pathManager: mockPathManager)
        let deviceDir1 = URL(fileURLWithPath: "/Users/test/Library/Developer/CoreSimulator/Devices/device1")
        let deviceDir2 = URL(fileURLWithPath: "/Users/test/Library/Developer/CoreSimulator/Devices/device2")
        
        mockFileManager.mockContents = [deviceDir1, deviceDir2]
        mockFileManager.existingFiles = await [
            deviceDir1.appendingPathComponent(PathConstants.devicePlist).path,
            deviceDir2.appendingPathComponent(PathConstants.devicePlist).path
        ]
        
        let result = try await repository.getDeviceDirectories()
        
        #expect(result.count == 2)
        #expect(result.contains(deviceDir1))
        #expect(result.contains(deviceDir2))
    }
    
    @Test("getDeviceDirectories filters out directories without device.plist")
    func getDeviceDirectoriesFiltersInvalidDirectories() async throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        let repository = await SimulatorRepositoryImpl(fileManager: mockFileManager, pathManager: mockPathManager)
        let validDir = URL(fileURLWithPath: "/Users/test/Library/Developer/CoreSimulator/Devices/valid")
        let invalidDir = URL(fileURLWithPath: "/Users/test/Library/Developer/CoreSimulator/Devices/invalid")
        
        mockFileManager.mockContents = [validDir, invalidDir]
        mockFileManager.existingFiles = await [
            validDir.appendingPathComponent(PathConstants.devicePlist).path
        ]
        
        let result = try await repository.getDeviceDirectories()
        
        #expect(result.count == 1)
        #expect(result.contains(validDir))
        #expect(!result.contains(invalidDir))
    }
    
    @Test("getDeviceDirectories throws error when cannot access folder")
    func getDeviceDirectoriesThrowsErrorOnAccessFailure() async throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        let repository = await SimulatorRepositoryImpl(fileManager: mockFileManager, pathManager: mockPathManager)
        
        mockFileManager.shouldThrowError = true
        #expect(throws: SimulatorError.self) {
            try repository.getDeviceDirectories()
        }
    }
    
    @Test("getDeviceDirectories returns empty array when no valid devices")
    func getDeviceDirectoriesReturnsEmptyArrayWhenNoDevices() async throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        let repository = await SimulatorRepositoryImpl(fileManager: mockFileManager, pathManager: mockPathManager)
        let result = try await repository.getDeviceDirectories()
        
        mockFileManager.mockContents = []
        #expect(result.isEmpty)
    }
    
    
    @Test("readDevicePlist throws error for invalid plist format")
    func readDevicePlistThrowsErrorForInvalidFormat() throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        
        let deviceDir = URL(fileURLWithPath: "/Users/test/device1")
        
        mockFileManager.plistData = try PropertyListSerialization.data(fromPropertyList: ["item1", "item2"], format: .xml, options: 0)
        
        let repository = TestableSimulatorRepository(
            fileManager: mockFileManager,
            pathManager: mockPathManager,
            dataLoader: { _ in
                guard let data = mockFileManager.plistData else {
                    throw NSError(domain: "test", code: -1)
                }
                return data
            }
        )
        
        do {
            _ = try repository.readDevicePlist(at: deviceDir)
            Issue.record("Expected invalidPlistFormat error")
        } catch let error as SimulatorError {
            switch error {
            case .invalidPlistFormat:
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test("readDevicePlist throws error when plist file does not exist")
    func readDevicePlistThrowsErrorWhenFileNotExists() throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        
        let deviceDir = URL(fileURLWithPath: "/Users/test/nonexistent")
        
        mockFileManager.shouldThrowDataError = true
        
        let repository = TestableSimulatorRepository(
            fileManager: mockFileManager,
            pathManager: mockPathManager,
            dataLoader: { _ in
                if mockFileManager.shouldThrowDataError {
                    throw NSError(domain: "test", code: -1)
                }
                throw NSError(domain: "test", code: -1)
            }
        )
        
        do {
            _ = try repository.readDevicePlist(at: deviceDir)
            Issue.record("Expected cannotReadPlist error")
        } catch let error as SimulatorError {
            switch error {
            case .cannotReadPlist:
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test("readDevicePlist successfully reads valid plist")
    func readDevicePlistReadsValidPlist() throws {
        let mockFileManager = MockFileManager()
        let mockPathManager = MockPathManager()
        
        let deviceDir = URL(fileURLWithPath: "/Users/test/device1")
        let expectedDict: [String: Any] = ["name": "iPhone 15", "udid": "123-456"]
        
        mockFileManager.plistData = try PropertyListSerialization.data(fromPropertyList: expectedDict, format: .xml, options: 0)
        
        let repository = TestableSimulatorRepository(
            fileManager: mockFileManager,
            pathManager: mockPathManager,
            dataLoader: { _ in
                guard let data = mockFileManager.plistData else {
                    throw NSError(domain: "test", code: -1)
                }
                return data
            }
        )
        
        let result = try repository.readDevicePlist(at: deviceDir)
        
        #expect(result["name"] as? String == "iPhone 15")
        #expect(result["udid"] as? String == "123-456")
    }
}

//MARK: - Mock Classes
final class MockFileManager: FileManager {
    var mockContents: [URL] = []
    var existingFiles: [String] = []
    var shouldThrowError = false
    var shouldThrowDataError = false
    var plistData: Data?
    var mockDirectoryContents: [URL: [URL]] = [:]
    
    
    override var homeDirectoryForCurrentUser: URL {
        return URL(fileURLWithPath: "/Users/test")
    }
    
    override func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }
        
        if let contents = mockDirectoryContents[url] {
            return contents
        }
        return mockContents
    }
    
    override func fileExists(atPath path: String) -> Bool {
        return existingFiles.contains(path)
    }
}

// Mock data loader for testing Data(contentsOf:)
final class MockDataLoader {
    static let shared = MockDataLoader()
    private var mockFileManager: MockFileManager?
    
    func configure(fileManager: MockFileManager) {
        self.mockFileManager = fileManager
    }
    
    func loadData(from url: URL) throws -> Data {
        guard let fileManager = mockFileManager else {
            throw NSError(domain: "test", code: -1)
        }
        
        if fileManager.shouldThrowDataError {
            throw NSError(domain: "test", code: -1)
        }
        
        if let data = fileManager.plistData {
            return data
        }
        
        throw NSError(domain: "test", code: -1)
    }
}

final class MockPathManager: PathManager {
    var simulatorPath: String = "Library/Developer/CoreSimulator/Devices"
    var coreDataPath: String = "Library/Application Support"
    var swiftDataPath: String = "Library/Application Support"
    var userDefaultsPath: String = "Library/Preferences"
    
    func selectFolder(for binding: Binding<String>) {
        // Mock implementation - not needed for SimulatorRepository tests
    }
    
    func resetPaths() {
        // Mock implementation - not needed for SimulatorRepository tests
    }
}

// Testable version of SimulatorRepository that accepts a custom data loader
final class TestableSimulatorRepository: SimulatorRepository {
    private let fileManager: FileManager
    private let pathManager: PathManager
    private let dataLoader: (URL) throws -> Data
    
    init(fileManager: FileManager, pathManager: PathManager, dataLoader: @escaping (URL) throws -> Data) {
        self.fileManager = fileManager
        self.pathManager = pathManager
        self.dataLoader = dataLoader
    }
    
    func getDeviceDirectories() throws -> [URL] {
        let basePath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(pathManager.simulatorPath)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil)
            
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
            let data = try dataLoader(plistURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            
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
