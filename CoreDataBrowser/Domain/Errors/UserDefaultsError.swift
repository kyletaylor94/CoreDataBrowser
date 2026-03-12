//
//  UserDefaultsError.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum UserDefaultsError: Error {
    case fileNotFound(URL)
    case invalidFormat(URL)
    case readError(URL)
    case cannotLoadApps(URL)
    
    var errorDescription: String {
        switch self {
        case .fileNotFound(let url):
            return "UserDefaults file not found at: \(url.path)"
        case .invalidFormat(let url):
            return "Invalid UserDefaults file format at: \(url.path)"
        case .readError(let url):
            return "Error reading UserDefaults file at: \(url.path)"
        case .cannotLoadApps(let url):
            return "Cannot load apps from: \(url.path)"
        }
    }
}
