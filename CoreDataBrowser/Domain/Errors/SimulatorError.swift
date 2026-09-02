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
    case accessNotGranted
    
    var errorDescription: String? {
        switch self {
        case .cannotAccessDevicesFolder:
            return "Could not access the Simulator devices folder."
        case .cannotReadPlist:
            return "Could not read the simulator's device.plist file."
        case .invalidPlistFormat:
            return "The device.plist file has an invalid format."
        case .accessNotGranted:
            return "Access to the Simulator devices folder was not granted. Please select the folder to continue."
        }
    }
    
    static func == (lhs: SimulatorError, rhs: SimulatorError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidPlistFormat, .invalidPlistFormat):
            return true
        case (.cannotAccessDevicesFolder, .cannotAccessDevicesFolder),
            (.cannotReadPlist, .cannotReadPlist),
            (.accessNotGranted, .accessNotGranted):
            return true
        default:
            return false
        }
    }
}
