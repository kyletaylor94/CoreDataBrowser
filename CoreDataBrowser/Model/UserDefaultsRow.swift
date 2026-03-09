//
//  UserDefaultsRow.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation

struct UserDefaultsRow: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let type: String
}
