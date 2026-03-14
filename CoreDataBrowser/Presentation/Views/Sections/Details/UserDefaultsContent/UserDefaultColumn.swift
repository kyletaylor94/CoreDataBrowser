//
//  UserDefaultColumn.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

enum UserDefaultColumn: String, CaseIterable , Identifiable {
    case key = "Key"
    case value = "Value"
    case type = "Type"
    var id: String { return self.rawValue }
}
