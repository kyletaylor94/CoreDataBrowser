//
//  SimulatorViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation

@MainActor
@Observable
class SimulatorViewModel {
    var devices: [SimulatorDevice] = []
    var selectedDevice: SimulatorDevice? = nil
    
    var currentError: SimulatorError? = nil
    var shouldShowError: Bool = false
    var isLoading = false
    
    private let useCase: SimulatorUseCase
    
    init(useCase: SimulatorUseCase) {
        self.useCase = useCase
    }
    
    func loadSimulators() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            devices = try await useCase.execute()
        } catch let error as SimulatorError {
            setError(error)
        } catch {
            setError(SimulatorError.invalidPlistFormat)
        }
    }
    
    func runTimeTextReplacing(device: SimulatorDevice) -> String {
        return device.runTime.replacingOccurrences(
            of: AppConstants.runtimeReplacing,
            with: ""
        )
    }
    
    private func setError(_ error: SimulatorError) {
        self.currentError = error
        self.shouldShowError = true
        print("\(error.localizedDescription)")
    }
}
