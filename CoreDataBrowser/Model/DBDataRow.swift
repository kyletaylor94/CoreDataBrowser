//
//  CoreDataRow.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation

struct DBDataRow: Identifiable {
    let id = UUID()
    let values: [String]
}
