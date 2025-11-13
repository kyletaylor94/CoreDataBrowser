//
//  UserDefaultsTable.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 08..
//

import Foundation

struct UserDefaultsTable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let columns: [String]
    let rows: [[String]]
    let types: [String]
}
