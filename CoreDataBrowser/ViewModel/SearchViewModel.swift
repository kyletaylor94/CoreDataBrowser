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
    
    /// Executes the search based on the current `searchedText` and updates the results.
    /// - Note: This function uses the `SearchUseCase` to perform the search and updates the corresponding properties with the results.
    func search(text: String, devices: [SimulatorDevice], tables: [DBDataTable]) {
        let result = useCase.execute(text: text, devices: devices, tables: tables)
        searchedSimulator = result.simulators
        searchedTables = result.tables
        searchedColumns = result.columns
        searchedRows = result.rows
    }
    
    /// Highlights the matched text in the given string using `AttributedString`.
    /// - Parameter text: The original text to search within.
    /// - Returns: A `Text` view with the matched text highlighted.
    /// - Note: This function uses `AttributedString` to apply background and foreground colors to the matched text. It performs a case-insensitive search and highlights the first occurrence of the `searchedText` within the provided `text`.
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
