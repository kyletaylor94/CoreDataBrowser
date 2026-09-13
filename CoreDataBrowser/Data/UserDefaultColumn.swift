//
//  UserDefaultColumn.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

enum UserDefaultColumn: CaseIterable, Identifiable {
    case key
    case value
    case type

    var id: String {
        name
    }

    var name: String {
        switch self {
        case .key:
            DatabaseConstants.UserDefaults.key
        case .value:
            DatabaseConstants.UserDefaults.value
        case .type:
            DatabaseConstants.UserDefaults.type
        }
    }
}
