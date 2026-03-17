//
//  UserDefaultsRepositoryTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 16..
//

import Testing
import Foundation
@testable import CoreDataBrowser

struct UserDefaultsRepositoryTests {
    
    @Test("loadPlistFiles returns valid plist files")
    func loadPlistFilesReturnsValidFiles() async throws {
        let mockFileManager = MockFileManager()
        let repository = await UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let devicePath = URL(fileURLWithPath: "/Users/test/device1")
        let device = SimulatorDevice(id: UUID(), name: "iPhone 15", state: "Booted", runTime: "iOS 17.0", path: devicePath)
        
        let app1 = devicePath.appendingPathComponent("data/Containers/Data/Application/app1")
        let app2 = devicePath.appendingPathComponent("data/Containers/Data/Application/app2")
        
        let prefs1 = app1.appendingPathComponent("Library/Preferences")
        let prefs2 = app2.appendingPathComponent("Library/Preferences")
        
        let plist1 = prefs1.appendingPathComponent("com.myapp.settings.plist")
        let plist2 = prefs2.appendingPathComponent("com.myapp.data.plist")
        let applePlist = prefs1.appendingPathComponent("com.apple.system.plist")
        
        mockFileManager.mockContents = [app1, app2]
        mockFileManager.existingFiles = [prefs1.path, prefs2.path]
        mockFileManager.mockDirectoryContents = [
            prefs1: [plist1, applePlist],
            prefs2: [plist2]
        ]
        
        let result = try await repository.loadPlistFiles(for: device)
        
        #expect(result.count == 2)
        #expect(result.contains(plist1))
        #expect(result.contains(plist2))
        #expect(!result.contains(applePlist))
    }
    
    @Test("loadPlistFiles filters out Apple system plists")
    func loadPlistFilesFiltersApplePlists() async throws {
        let mockFileManager = MockFileManager()
        let repository = await UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let devicePath = URL(fileURLWithPath: "/Users/test/device1")
        let device = SimulatorDevice(id: UUID(), name: "iPhone 15", state: "Booted", runTime: "iOS 17.0", path: devicePath)
        
        let app1 = devicePath.appendingPathComponent("data/Containers/Data/Application/app1")
        let prefs1 = app1.appendingPathComponent("Library/Preferences")
        
        let userPlist = prefs1.appendingPathComponent("com.myapp.settings.plist")
        let applePlist = prefs1.appendingPathComponent("com.apple.preferences.plist")
        
        mockFileManager.mockContents = [app1]
        mockFileManager.existingFiles = [prefs1.path]
        mockFileManager.mockDirectoryContents = [
            prefs1: [userPlist, applePlist]
        ]
        
        let result = try await repository.loadPlistFiles(for: device)
        
        #expect(result.count == 1)
        #expect(result.contains(userPlist))
        #expect(!result.contains(applePlist))
    }
    
    @Test("loadPlistFiles returns empty array when no apps exist")
    func loadPlistFilesReturnsEmptyWhenNoApps() async throws {
        let mockFileManager = MockFileManager()
        let repository = await UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let devicePath = URL(fileURLWithPath: "/Users/test/device1")
        let device = SimulatorDevice(id: UUID(), name: "iPhone 15", state: "Booted", runTime: "iOS 17.0", path: devicePath)
        
        mockFileManager.mockContents = []
        
        let result = try await repository.loadPlistFiles(for: device)
        
        #expect(result.isEmpty)
    }
    
    @Test("loadPlistFiles throws error when cannot access apps folder")
    func loadPlistFilesThrowsErrorOnAccessFailure() async throws {
        let mockFileManager = MockFileManager()
        let repository = await UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let devicePath = URL(fileURLWithPath: "/Users/test/device1")
        let device = SimulatorDevice(id: UUID(), name: "iPhone 15", state: "Booted", runTime: "iOS 17.0", path: devicePath)
        
        mockFileManager.shouldThrowError = true
        
        do {
            _ = try await repository.loadPlistFiles(for: device)
            Issue.record("Expected cannotLoadApps error")
        } catch let error as UserDefaultsError {
            switch error {
            case .cannotLoadApps:
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test("loadPlistFiles skips apps without Preferences folder")
    func loadPlistFilesSkipsAppsWithoutPreferences() async throws {
        let mockFileManager = MockFileManager()
        let repository = await UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let devicePath = URL(fileURLWithPath: "/Users/test/device1")
        let device = SimulatorDevice(id: UUID(), name: "iPhone 15", state: "Booted", runTime: "iOS 17.0", path: devicePath)
        
        let app1 = devicePath.appendingPathComponent("data/Containers/Data/Application/app1")
        let app2 = devicePath.appendingPathComponent("data/Containers/Data/Application/app2")
        
        let prefs1 = app1.appendingPathComponent("Library/Preferences")
        let plist1 = prefs1.appendingPathComponent("com.myapp.settings.plist")
        
        mockFileManager.mockContents = [app1, app2]
        mockFileManager.existingFiles = [prefs1.path]
        mockFileManager.mockDirectoryContents = [
            prefs1: [plist1]
        ]
        
        let result = try await repository.loadPlistFiles(for: device)
        
        #expect(result.count == 1)
        #expect(result.contains(plist1))
    }
    
    @Test("readPlistFile successfully reads valid plist")
    func readPlistFileReadsValidPlist() throws {
        let mockFileManager = MockFileManager()
        let repository = UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let expectedDict: [String: Any] = ["key1": "value1", "key2": 123]
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".plist")
        try (expectedDict as NSDictionary).write(to: tempURL)
        
        let result = try repository.readPlistFile(at: tempURL)
        
        try? FileManager.default.removeItem(at: tempURL)
        
        #expect(result["key1"] as? String == "value1")
        #expect(result["key2"] as? Int == 123)
    }
    
    @Test("readPlistFile throws error for invalid format")
    func readPlistFileThrowsErrorForInvalidFormat() throws {
        let mockFileManager = MockFileManager()
        let repository = UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let plistURL = URL(fileURLWithPath: "/Users/test/invalid.plist")
        
        do {
            _ = try repository.readPlistFile(at: plistURL)
            Issue.record("Expected invalidFormat error")
        } catch let error as UserDefaultsError {
            switch error {
            case .invalidFormat:
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test("getFileSize returns correct file size")
    func getFileSizeReturnsCorrectSize() throws {
        let mockFileManager = MockFileManager()
        let repository = UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        let testData = "Test content".data(using: .utf8)!
        try testData.write(to: testURL)
        
        let size = repository.getFileSize(at: testURL)
        
        try? FileManager.default.removeItem(at: testURL)
        
        #expect(size == testData.count)
    }
    
    @Test("getFileSize returns zero for non-existent file")
    func getFileSizeReturnsZeroForNonExistentFile() {
        let mockFileManager = MockFileManager()
        let repository = UserDefaultsRepositoryImpl(fileManager: mockFileManager)
        
        let nonExistentURL = URL(fileURLWithPath: "/Users/test/nonexistent.plist")
        
        let size = repository.getFileSize(at: nonExistentURL)
        
        #expect(size == 0)
    }
}
