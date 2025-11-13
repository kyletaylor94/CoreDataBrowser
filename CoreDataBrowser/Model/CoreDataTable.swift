//
//  CoreDataTable.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 03..
//

import Foundation

struct CoreDataTable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let columns: [String]
    let rows: [[String]]
    let types: [String]
}
