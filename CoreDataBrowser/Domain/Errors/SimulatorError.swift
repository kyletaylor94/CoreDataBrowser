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
    case selectedSpecificSimulatorFolder
    
    var errorDescription: String? {
        switch self {
        case .cannotAccessDevicesFolder:
            return AppConstants.SimulatorStrings.cannotAccessDeviceFolder
        case .cannotReadPlist:
            return AppConstants.SimulatorStrings.cannotReadPList
        case .invalidPlistFormat:
            return AppConstants.SimulatorStrings.invalidPListFormat
        case .accessNotGranted:
            return AppConstants.SimulatorStrings.accessNotGranted
        case .selectedSpecificSimulatorFolder:
            return AppConstants.SimulatorStrings.selectedSpecificSimulatorFolder
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
