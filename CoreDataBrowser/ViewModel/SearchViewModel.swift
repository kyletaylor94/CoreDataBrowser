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
    var searchedText: String = ""
    var searchedSimulator: [SimulatorDevice] = []
    var searchedTables: [DBDataTable] = []
    var searchedColumns: [String] = []
    var searchedRows: [String] = []
    
    func search(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) {
        if text.isEmpty { return }
        searchedSimulator = devices.filter({ $0.name.contains(text.lowercased()) })
        
        if searchedSimulator.isEmpty {
            searchInTables(text: text, tables: tables)
        }
        
        if searchedSimulator.isEmpty && searchedTables.isEmpty {
            searchInData(text: text, tables: tables)
        }
    }
    
    func highlightMatch(in text: String) -> Text {
        guard !searchedText.isEmpty else { return Text(text) }
        var attributed = AttributedString(text)
        
        if let range = attributed.range(of: searchedText, options: [.caseInsensitive]) {
            attributed[range].backgroundColor = .yellow
            attributed[range].foregroundColor = .black
        }
        return Text(attributed)
    }
    
 
    private func searchInTables(text: String, tables: [DBDataTable]) {
        if text.isEmpty { return }
        searchedTables = tables.filter({ $0.columns.contains(where: { $0.contains(text.lowercased()) }) })
    }
    
    
    private func searchInData(text: String, tables: [DBDataTable]) {
        if text.isEmpty { return }
        let columns = tables.flatMap { $0.columns }
        let rows = tables.flatMap { $0.rows }
        self.searchedColumns = columns.filter({ $0.contains(text.lowercased()) })
        
        let filteredRows = rows.filter { row in
            row.contains { cell in
                cell.lowercased().contains(text.lowercased())
            }
        }
        self.searchedRows = filteredRows.flatMap { $0 }
    }
}
