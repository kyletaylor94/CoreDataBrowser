//
//  SimulatorViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation

enum CustomErrorTypes: LocalizedError {
    case cannotAccessDevicesFolder
    case cannotReadPlist(URL)
    case cannotOpenDatabase(URL)
    case cannotLoadApps(URL)
    case unknown(Error)
    
    var errorDescription: String? {
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

@MainActor
@Observable
class SimulatorViewModel {
    var devices: [SimulatorDevice] = []
    var currentError: CustomErrorTypes? = nil
    var shouldShowError: Bool = false
    var selectedDevice: SimulatorDevice? = nil
    var isLoading = false
    
    private let fileManager = FileManager.default
    
    private let pathManager: PathManager
    
    init(pathManager: PathManager) {
        self.pathManager = pathManager
    }
    
    func loadSimulators() {
        isLoading = true
        defer { isLoading = false }
        
       // let basePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(Constants.SIMULATOR_PATH)
        let basePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(pathManager.simulatorPath)
        guard let contents = try? fileManager.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil) else {
            setError(.cannotAccessDevicesFolder)
            return
        }
        
        var loadedDevices: [SimulatorDevice] = []
        
        for deviceURL in contents {
            let plistURL = deviceURL.appendingPathComponent(Constants.devicePList)
            guard fileManager.fileExists(atPath: plistURL.path) else { continue }
            
            do {
                let data = try Data(contentsOf: plistURL)
                let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                guard let dict = plist as? [String: Any] else { continue }
                
                let (name, state, runtime) = checkKeys(dict: dict)
                
                guard state == "Booted" else { continue }
                
                loadedDevices.append(
                    SimulatorDevice(
                        id: UUID(),
                        name: name,
                        state: state,
                        runTime: runtime,
                        path: deviceURL
                    )
                )
            } catch {
                setError(.cannotReadPlist(plistURL))
            }
        }
        self.sortedDevices(devices: Array(Set(loadedDevices)))
    }
    
    func runTimeTextReplacing(device: SimulatorDevice) -> String {
        return device.runTime.replacingOccurrences(
            of: Constants.runTimeReplacing,
            with: "")
    }
    
    private func setError(_ error: CustomErrorTypes) {
        self.currentError = error
        self.shouldShowError = true
        print("\(error.localizedDescription)")
    }
    
    private func sortedDevices(devices: [SimulatorDevice]) {
        self.devices = devices.sorted(by: { $0.name < $1.name })
    }
    
    private func checkKeys(dict: [String: Any]) -> (String, String, String) {
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
