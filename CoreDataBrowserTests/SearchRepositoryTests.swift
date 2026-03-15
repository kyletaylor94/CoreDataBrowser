//
//  SearchRepositoryTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 15..
//

import Testing
import Foundation
@testable import CoreDataBrowser

struct SearchRepositoryTests {

    @Test("searchDevices returns matching devices")
    func searchDevicesReturnsMatchingDevices() async throws {
        let repository = await SearchRepositoryImpl()
        let devices = [
            SimulatorDevice(id: UUID(), name: "iPhone 15 Pro", state: "Booted", runTime: "iOS 16.0", path: URL(string: "file:///path/to/device1")!),
            SimulatorDevice(id: UUID(), name: "iPhone 14", state: "Shutdown", runTime: "iOS 17.0", path: URL(string: "file:///path/to/device2")!),
            SimulatorDevice(id: UUID(), name: "iPhone 13", state: "Booted", runTime: "iOS 15.0", path: URL(string: "file:///path/to/device3")!),
        ]
        
        let result = await repository.searchDevices(with: "iPhone", in: devices)
        #expect(result.count == 3)
        #expect(result.contains(where: { $0.name == "iPhone 15 Pro" }))
        #expect(result.contains(where: { $0.name == "iPhone 14" }))
    }
    
    @Test("searchDevices is case insesitive")
    func searchDevicesInCaseInsensitive() async throws {
        let repository = await SearchRepositoryImpl()
        let devices = [
            SimulatorDevice(id: UUID(), name: "iPhone 15 Pro", state: "Booted", runTime: "iOS 17.0", path: URL(string: "file:///path/to/device1")!)
        ]
        
        let result = await repository.searchDevices(with: "iphone", in: devices)
        #expect(result.count == 1)
        #expect(result.first?.name == "iPhone 15 Pro")
    }
    
    @Test("searchDevices returns empty array when no match")
    func searchDevicesReturnsEmptyArrayWhenNoMatch() async throws {
        let repository = await SearchRepositoryImpl()
        let devices = [
            SimulatorDevice(id: UUID(), name: "iPhone 15 Pro", state: "Booted", runTime: "iOS 17.0", path: URL(string: "file:///path/to/device1")!)
        ]
        
        let result = await repository.searchDevices(with: "iPad", in: devices)
        #expect(result.isEmpty)
    }
    
    @Test("searchDevices returns empty array when device list is empty")
    func searchDevicesReturnsEmptyArrayWhenDeviceListIsEmpty() async throws {
        let repository = await SearchRepositoryImpl()
        let devices: [SimulatorDevice] = []
        let result = await repository.searchDevices(with: "iPad", in: devices)
        #expect(result.isEmpty)
    }
    
    @Test("searchTables in case insensitive")
    func searchTablesInCaseInsensitive() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "name", "email"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Products", columns: ["id", "price", "title"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "user_id", "total"], rows: [], types: [], fileSize: 0),
        ]
        let result = await repository.searchTables(with: "name", in: tables)
        #expect(result.count == 1)
    }
    
    @Test("searchTables returns empty array when no matches")
    func searchTablesReturnsEmptyArrayWhenNoMatches() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "name", "email"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Products", columns: ["id", "price", "title"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "user_id", "total"], rows: [], types: [], fileSize: 0)
        ]
        let result = await repository.searchTables(with: "xyz", in: tables)
        #expect(result.isEmpty)
    }
    
    @Test("searchColumns returns matching column names")
    func searchColumnsReturnMatchingColumnNames() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name", "email"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Products", columns: ["id", "product_name", "title"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "user_id", "total"], rows: [], types: [], fileSize: 0)
        ]
        
        let result = await repository.searchColumns(with: "name", in: tables)
        #expect(result.count == 2)
        #expect(result.contains("user_name"))
        #expect(result.contains("product_name"))
    }
    
    @Test("searchColumns is case insensitive")
    func searchColumnsIsCaseInsensitive() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["ID", "Name", "Email"], rows: [], types: [], fileSize: 0)
        ]
        let result = await repository.searchColumns(with: "id", in: tables)
        #expect(result.count == 1)
        #expect(result.first == "ID")
    }
    
    @Test("searchColumns returns empty array when no matches")
    func searchColumnsReturnsEmptyArrayWhenNoMatches() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name", "email"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Products", columns: ["id", "product_name", "title"], rows: [], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "user_id", "total"], rows: [], types: [], fileSize: 0)
        ]
        let result = await repository.searchColumns(with: "xyz", in: tables)
        #expect(result.isEmpty)
    }
    
    @Test("searchColumns returns empty array when table list is empty")
    func searchColumnsReturnsEmptyArrayWhenTableListIsEmpty() async throws {
        let repository = await SearchRepositoryImpl()
        let result = await repository.searchColumns(with: "name", in: [])
        #expect(result.isEmpty)
    }
    
    @Test("searchRows returns matching cell values")
    func searchRowsReturnsMatchingCellValues() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name", "email"], rows: [["1", "Alice", "alice@test.com"], ["2", "Bob", "bob@test.com"]], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "user_id", "total"], rows: [["1", "Jack", "100"], ["2", "Cooper", "200"]], types: [], fileSize: 0)
        ]
        let result = await repository.searchRows(with: "Cooper", in: tables)
        #expect(result.contains("Cooper"))
        #expect(!result.contains("Alice"))
    }
    
    @Test("searchRows is case insensitive")
    func searchRowsIsCaseInSensitive() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name"], rows: [["1", "Alice"], ["2", "bob"]], types: [], fileSize: 0),
            DBDataTable(name: "Orders", columns: ["id", "name"], rows: [["1", "cooper"]], types: [], fileSize: 0)
        ]
        let result = await repository.searchRows(with: "Cooper", in: tables)
        #expect(result.contains("cooper"))
        #expect(!result.contains("Alice"))
    }
    
    @Test("searchRows returns empty array when no matches")
    func searchRowsReturnsEmptyArrayWhenNoMatches() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name", "email"], rows: [["1", "Alice"], ["2", "bob"], ["3", "Charlie"]], types: [], fileSize: 0),
        ]
        let result = await repository.searchRows(with: "xxy", in: tables)
        #expect(result.isEmpty)
    }
    
    @Test("searchRows returns empty array when tables have no rows")
    func searchRowsReturnsEmptyArrayWhenTablesHaveNoRows() async throws {
        let repository = await SearchRepositoryImpl()
        let tables = [
            DBDataTable(name: "Users", columns: ["id", "user_name", "email"], rows: [], types: [], fileSize: 0),
        ]
        let result = await repository.searchRows(with: "John", in: tables)
        #expect(result.isEmpty)
    }
    
    @Test("searchRows returns empty array when table list is empty")
    func searchRowsReturnsEmptyArrayWhenTableListIsEmpty() async throws {
        let repository = await SearchRepositoryImpl()
        let result = await repository.searchRows(with: "Alice", in: [])
        #expect(result.isEmpty)
    }
}
