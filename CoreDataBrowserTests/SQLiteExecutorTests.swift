//
//  SQLiteExecutorTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 22..
//

import Testing
import Foundation
import SQLite3
@testable import CoreDataBrowser

struct SQLiteExecutorTests {
    
    @Test("Fetch entitites returns all table names")
    func fetchEntitiesReturnsAllTableName() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Person (id INTEGER, name TEXT);", on: db)
            exec("CREATE TABLE Purchase (id INTEGER, total REAL);", on: db)
        }
        
        let entities = await executor.fetchEntities(in: dbURL)
        
        #expect(entities.contains("Person"))
        #expect(entities.contains("Purchase"))
        #expect(entities.count == 2)
    }
    
    @Test("Fetch entities returns empty array for empty db")
    func fetchEntitiesReturnsEmptyArrayForEmptyDB() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { _ in }
        
        let entities = await executor.fetchEntities(in: dbURL)
        #expect(entities.isEmpty)
    }
    
    @Test("Fetch entities returns empty array for non-existent db")
    func fetchEntitiesReturnsEmptyArrayForNonExistentDB() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).sqlite")
        
        let entities = await executor.fetchEntities(in: dbURL)
        #expect(entities.isEmpty)
    }
    
    @Test("Fetch columns with types returns correct columns and types")
    func fetchColumnsWithTypesReturnsCorrectColumnsAndTypes() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Employee (id INTEGER, name TEXT, salary REAL, photo BLOB);", on: db)
        }
        
        let (columns, types) = await executor.fetchColumnsWithTypes(databaseURL: dbURL, table: "Employee")
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
        #expect(columns.contains("salary"))
        #expect(columns.contains("photo"))
        
        let idIndex = columns.firstIndex(of: "id")
        let nameIndex = columns.firstIndex(of: "name")
        let salaryIndex = columns.firstIndex(of: "salary")
        
        #expect(types[idIndex!] == "INTEGER")
        #expect(types[nameIndex!] == "TEXT")
        #expect(types[salaryIndex!] == "REAL")
    }
    
    @Test("Fetch columns with types returns empty arrays for non-existent table")
    func fetchColumnsWithTypesReturnsEmptyArraysForNonExistentTable() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Person (id INTEGER);", on: db)
        }
        
        let (columns, types) = await executor.fetchColumnsWithTypes(databaseURL: dbURL, table: "NonExistent")
        
        #expect(columns.isEmpty)
        #expect(types.isEmpty)
    }
    
    @Test("Fetch rows returns all rows with correct values")
    func fetchRowsReturnsAllRowsWithCorrectValues() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Product (id INTEGER, name TEXT, price REAL);", on: db)
            exec("INSERT INTO Product VALUES (1, 'Apple', 1.99);", on: db)
            exec("INSERT INTO Product VALUES (2, 'Banana', 0.99);", on: db)
        }
        
        let rows = await executor.fetchRows(at: dbURL, query: "SELECT * FROM Product")
        
        #expect(rows.count == 2)
        #expect(rows[0].contains("1"))
        #expect(rows[0].contains("Apple"))
        #expect(rows[0].contains("1.99"))
        #expect(rows[1].contains("2"))
        #expect(rows[1].contains("Banana"))
    }
    
    @Test("Fetch rows returns empty array for empty table")
    func fetchRowsReturnsEmptyArrayforEmptyTable() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE EmptyTable (id INTEGER);", on: db)
        }
        
        let rows = await executor.fetchRows(at: dbURL, query: "SELECT * FROM EmptyTable")
        #expect(rows.isEmpty)
    }
    
    @Test("Fetch rows handles NULL values correctly")
    func fetchRowsHandlesNullValuesCorrectly() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Person (id INTEGER, nickname TEXT);", on: db)
            exec("INSERT INTO Person VALUES (1, NULL);", on: db)
        }
        
        let rows = await executor.fetchRows(at: dbURL, query: "SELECT * FROM Person")
        #expect(rows.count == 1)
        #expect(rows[0].contains("NULL"))
    }
    
    @Test("Fetch rows handles INT values correctly")
    func fetchRowsHandlesIntValuesCorrectly() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in
            exec("CREATE TABLE Counter (value INTEGER);", on: db)
            exec("INSERT INTO Counter VALUES (9999999);", on: db)
        }
        
        let rows = await executor.fetchRows(at: dbURL, query: "SELECT * FROM Counter")
        #expect(rows.count == 1)
        #expect(rows[0][0] == "9999999")
    }
    
    @Test("Fetch rows handles BLOB values using blobdecoder")
    func fetchRowsHandlesBlobValuesUsingBlobDecoder() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        let text = "BlobText"
        let blobData = text.data(using: .utf8)!
        
        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK, let db else { return }
        defer { sqlite3_close(db) }
        
        exec("CREATE TABLE Files (id INTEGER, content BLOB);", on: db)
        
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, "INSERT INTO Files VALUES (1, ?);", -1, &stmt, nil)
        blobData.withUnsafeBytes { ptr in
            sqlite3_bind_blob(stmt, 1, ptr.baseAddress, Int32(blobData.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        
        let rows = await executor.fetchRows(at: dbURL, query: "SELECT * FROM Files")
        
        #expect(rows.count == 1)
        #expect(rows[0][1] == text)
    }
    
    
    @Test("Execute retuns nil for invalid db path")
    func executeReturnsNilForInvalidDBPath() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).sqlite")
        
        let result = await executor.execute(at: dbURL, query: "SELECT * FROM SomeTable") { _ in "value" }
        #expect(result == nil)
    }
    
    @Test("Execute returns nil for invalid SQL query")
    func executeReturnsNulForInvalidSQLQuery() async throws {
        let blobDecoder = await BlobDecoder()
        let executor = await SQLiteExecutor(blobDecoder: blobDecoder)
        let dbURL = createTempDatabase()
        defer { try? FileManager.default.removeItem(at: dbURL) }
        
        setupDatabase(at: dbURL) { db in }
        
        let result = await executor.execute(at: dbURL, query: "INVALID SQL QUERY") { _ in "value" }
        #expect(result == nil)
    }
}


//MARK: - Helpers
extension SQLiteExecutorTests {
    private func createTempDatabase() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(".sqlite")
        return url
    }
    
    private func setupDatabase(at url: URL, using setup: (OpaquePointer) -> Void) {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db = db else { return }
        defer { sqlite3_close(db) }
        setup(db)
    }
    
    private func exec(_ query: String, on db: OpaquePointer) {
        sqlite3_exec(db, query, nil, nil, nil)
    }
}
