//
//  DBError.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum DBError: LocalizedError {
    case cannotLoadApps(URL)
    case cannotOpenDatabase(URL)
    case queryFailed(String)
    case invalidData(URL)
    
    var errorDescription: String {
        switch self {
        case .cannotLoadApps(let url):
            return "Cannot load apps from: \(url.path)"
        case .cannotOpenDatabase(let url):
            return "Cannot open SwiftData database at: \(url.path)"
        case .queryFailed(let query):
            return "Query failed: \(query)"
        case .invalidData(let url):
            return "Invalid SwiftData store at: \(url.path)"
        }
    }
}
