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
    
    func execute(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) -> SearchResult {
        guard !text.isEmpty else {
            return emptyResults()
        }
        
        if let simulatorResults = searchSimulators(text: text, devices: devices) {
            return simulatorResults
        }
        
        if let tableResults = searchTable(text: text, tables: tables) {
            return tableResults
        }
        
        return searchColumnsAndRows(text: text, tables: tables)
    }
    
    func searchSimulators(text: String, devices: [SimulatorDevice]) -> SearchResult? {
        let simulators = repository.searchDevices(with: text, in: devices)
        guard !simulators.isEmpty else { return nil }
        return SearchResult(simulators: simulators, tables: [], columns: [], rows: [])
    }
    
    func searchTable(text: String, tables: [DBDataTable]) -> SearchResult? {
        let searchedTables = repository.searchTables(with: text, in: tables)
        guard !tables.isEmpty else { return nil }
        return SearchResult(simulators: [], tables: searchedTables, columns: [], rows: [])
    }
    
    func searchColumnsAndRows(text: String, tables: [DBDataTable]) -> SearchResult {
        let columns = repository.searchColumns(with: text, in: tables)
        let rows = repository.searchRows(with: text, in: tables)
        return SearchResult(simulators: [], tables: [], columns: columns, rows: rows)
    }
    
    func emptyResults() -> SearchResult {
        return SearchResult(simulators: [], tables: [], columns: [], rows: [])
    }
}
