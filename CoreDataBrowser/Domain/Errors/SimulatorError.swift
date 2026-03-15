//
//  SimulatorError.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum SimulatorError: LocalizedError, Equatable {
    case cannotAccessDevicesFolder(underlyingError: Error? = nil)
    case cannotReadPlist(underlyingError: Error)
    case invalidPlistFormat
    
    static func == (lhs: SimulatorError, rhs: SimulatorError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidPlistFormat, .invalidPlistFormat):
            return true
        case (.cannotAccessDevicesFolder, .cannotAccessDevicesFolder),
            (.cannotReadPlist, .cannotReadPlist):
            return true
        default:
            return false
        }
    }
}
