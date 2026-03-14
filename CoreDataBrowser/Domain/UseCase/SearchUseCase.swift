//
//  SearchUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol SearchUseCase {
    func execute(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) -> SearchResult
    func searchSimulators(text: String, devices: [SimulatorDevice]) -> SearchResult?
    func searchTable(text: String, tables: [DBDataTable]) -> SearchResult?
    func searchColumnsAndRows(text: String, tables: [DBDataTable]) -> SearchResult
    func emptyResults() -> SearchResult
}

final class SearchUseCaseImpl: SearchUseCase {
    private let repository: SearchRepository
    
    init(repository: SearchRepository) {
        self.repository = repository
    }
    
    /// Executes a search across simulators, tables, columns, and rows based on the provided text.
    /// - Parameters:
    ///  - text: The search query text.
    ///  - devices: The list of simulator devices to search through.
    ///  - tables: The list of database tables to search through.
    ///  - Returns: A `SearchResult` containing matching simulators, tables, columns, and rows.
    func execute(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) -> SearchResult {
        guard !text.isEmpty else { return emptyResults() }
        
        if let simulatorResults = searchSimulators(text: text, devices: devices) {
            return simulatorResults
        }
        
        if let tableResults = searchTable(text: text, tables: tables) {
            return tableResults
        }
        
        return searchColumnsAndRows(text: text, tables: tables)
    }
    
    /// Searches for simulators matching the provided text.
    /// - Parameters:
    /// - text: The search query text.
    /// - devices: The list of simulator devices to search through.
    /// - Returns: A `SearchResult` containing matching simulators, or `nil` if no matches are found.
    func searchSimulators(text: String, devices: [SimulatorDevice]) -> SearchResult? {
        let simulators = repository.searchDevices(with: text, in: devices)
        guard !simulators.isEmpty else { return nil }
        return SearchResult(simulators: simulators, tables: [], columns: [], rows: [])
    }
    
    /// Searches for tables matching the provided text.
    /// - Parameters:
    ///   - text: The search query text.
    ///   - tables: The list of database tables to search through.
    ///   - Returns: A `SearchResult` containing matching tables, or `nil` if no matches are found.
    func searchTable(text: String, tables: [DBDataTable]) -> SearchResult? {
        let searchedTables = repository.searchTables(with: text, in: tables)
        guard !tables.isEmpty else { return nil }
        return SearchResult(simulators: [], tables: searchedTables, columns: [], rows: [])
    }
    
    /// Searches for columns and rows matching the provided text.
    /// - Parameters:
    ///   - text: The search query text.
    ///   - tables: The list of database tables to search through.
    ///   - Returns: A `SearchResult` containing matching columns and rows.
    func searchColumnsAndRows(text: String, tables: [DBDataTable]) -> SearchResult {
        let columns = repository.searchColumns(with: text, in: tables)
        let rows = repository.searchRows(with: text, in: tables)
        return SearchResult(simulators: [], tables: [], columns: columns, rows: rows)
    }
    
    /// Returns an empty `SearchResult` with no matches for simulators, tables, columns, or rows.
    func emptyResults() -> SearchResult {
        return SearchResult(simulators: [], tables: [], columns: [], rows: [])
    }
}
