//
//  SimulatorError.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum SimulatorError: LocalizedError {
    case cannotAccessDevicesFolder
    case cannotReadPlist(URL)
    case cannotOpenDatabase(URL)
    case cannotLoadApps(URL)
    case unknown(Error)
    
    var errorDescription: String {
        switch self {
        case .cannotAccessDevicesFolder:
            return "Cannot access CoreSimulator devices folder."
        case .cannotReadPlist(let url):
            return "Failed to read device.plist at: \(url.lastPathComponent)"
        case .cannotOpenDatabase(let url):
            return "Failed to open database: \(url.lastPathComponent)"
        case .cannotLoadApps(let url):
            return "Failed to load apps for simulator: \(url.lastPathComponent)"
        case .unknown(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}
