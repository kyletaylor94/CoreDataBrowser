//
//  SimulatorUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

protocol SimulatorUseCase {
    func execute() async throws -> [SimulatorDevice]
}

final class SimulatorUseCaseImpl: SimulatorUseCase {
    private let repository: SimulatorRepository
    
    init(repository: SimulatorRepository) {
        self.repository = repository
    }
    
    /// Fetches all booted simulator devices by reading their plist files.
    /// - Returns: An array of `SimulatorDevice` representing the booted simulators.
    /// - Throws: `SimulatorError` if there are issues accessing the devices folder or reading plist files.
    func execute() async throws -> [SimulatorDevice] {
        let directories = try repository.getDeviceDirectories()
        var devices: [SimulatorDevice] = []
        
        for deviceURL in directories {
            do {
                let dict = try repository.readDevicePlist(at: deviceURL)
                let (name, state, runtime) = parseDeviceInfo(from: dict)
                
                guard state == "Booted" else { continue }
                
                devices.append(
                    SimulatorDevice(
                        id: UUID(),
                        name: name,
                        state: state,
                        runTime: runtime,
                        path: deviceURL
                    )
                )
            } catch let error as SimulatorError {
                throw SimulatorError.cannotReadPlist(underlyingError: error)
            }
        }
        return Array(Set(devices)).sorted(by: { $0.name < $1.name })
    }
    
    /// Parses the device information from a given dictionary, extracting the name, state, and runtime.
    /// - Parameter dict: A dictionary containing the device information from the plist file.
    /// - Returns: A tuple containing the device name, state, and runtime.
    /// - Note: The method handles both string and integer representations of the state, ensuring robust parsing.
    private func parseDeviceInfo(from dict: [String: Any]) -> (String, String, String) {
        let safeDict = dict.compactMapValues { $0 as? String }
        let name = safeDict["name"] ?? "N/A"
        let runtime = safeDict["runtime"] ?? "Unknown"
        
        let state: String
        if let s = safeDict["state"] {
            state = s
        } else if let n = dict["state"] as? Int {
            state = (n == 1) ? "Shutdown" : "Booted"
        } else {
            state = "Unknown"
        }
        return (name, state, runtime)
    }
}

