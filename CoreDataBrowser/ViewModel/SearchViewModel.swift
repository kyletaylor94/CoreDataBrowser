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
    
    private let useCase: SearchUseCase
    
    init(useCase: SearchUseCase) {
        self.useCase = useCase
    }
    
    func search(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) {
        let result = useCase.execute(text: text, devices: devices, tables: tables)
        
        searchedSimulator = result.simulators
        searchedTables = result.tables
        searchedColumns = result.columns
        searchedRows = result.rows
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
}
