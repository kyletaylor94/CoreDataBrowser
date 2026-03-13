//
//  SimulatorError.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum SimulatorError: LocalizedError {
    case cannotAccessDevicesFolder(underlyingError: Error? = nil)
    case cannotReadPlist(underlyingError: Error)
    case invalidPlistFormat
    
    var errorDescription: String? {
        switch self {
        case .cannotAccessDevicesFolder(let error):
            let base = "Cannot access CoreSimulator devices folder."
            if let error {
                return "\(base) Reason: \(error.localizedDescription)"
            }
            return base
        case .cannotReadPlist(let error):
            return "Cannot read device plist. Reason: \(error.localizedDescription)"
        case .invalidPlistFormat:
            return "Device plist has invalid format."
        }
    }
}
