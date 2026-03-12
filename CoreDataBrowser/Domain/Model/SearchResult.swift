//
//  SearchResult.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

struct SearchResult {
    let simulators: [SimulatorDevice]
    let tables: [DBDataTable]
    let columns: [String]
    let rows: [String]
}
