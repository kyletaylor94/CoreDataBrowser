//
//  SearchViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 08..
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class SearchViewModel {
    private var highlightCache: [String: Text] = [:]
    private let cacheLimit = 100
    
    var searchedSimulator: [SimulatorDevice] = []
    var searchedTables: [DBDataTable] = []
    var searchedColumns: [String] = []
    var searchedRows: [String] = []
    
    private let useCase: SearchUseCase
    
    init(useCase: SearchUseCase) {
        self.useCase = useCase
    }
    
    var searchedText: String = "" {
        didSet {
            highlightCache.removeAll()
        }
    }
    
    /// Executes the search based on the current `searchedText` and updates the results.
    /// - Note: This function uses the `SearchUseCase` to perform the search and updates the corresponding properties with the results.
    func search(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) {
        let result = useCase.execute(text: text, devices: devices, tables: tables)
        searchedSimulator = result.simulators
        searchedTables = result.tables
        searchedColumns = result.columns
        searchedRows = result.rows
        
        if highlightCache.count > cacheLimit {
            highlightCache.removeAll(keepingCapacity: true)
        }
    }
    
    private func highlightAllMatches(in text: String) -> Text {
        guard !searchedText.isEmpty else { return Text(text) }
        var attributed = AttributedString(text)
        var searchIndex = attributed.startIndex
        
        while searchIndex < attributed.endIndex {
            if let range = attributed[searchIndex...].range(of: searchedText.lowercased(),options: [.caseInsensitive]) {
                attributed[range].backgroundColor = .yellow
                attributed[range].foregroundColor = .black
                searchIndex = range.upperBound
            } else {
                break
            }
        }
        return Text(attributed)
    }
    
    func highlightMatch(in text: String) -> Text {
        if let cached = highlightCache[text] {
            return cached
        }
        
        let highlighted = highlightAllMatches(in: text)
        highlightCache[text] = highlighted
        return highlighted
    }
}
