//
//  SimulatorViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation
import SwiftUI

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
    
    /// Loads the list of simulators asynchronously. Sets the `isLoading` flag to true while loading and handles errors by updating the `currentError` and `shouldShowError` properties.
    /// - Note: The `defer` statement ensures that the `isLoading` flag is reset to false regardless of whether the loading succeeds or fails.
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
    
    /// Returns a cleaned-up runtime string for a given simulator device by removing specific substrings defined in `AppConstants.runtimeReplacing`.
    /// - Parameter device: The `SimulatorDevice` for which to format the runtime string.
    /// - Returns: A formatted runtime string with specific substrings removed.
    func runTimeTextReplacing(device: SimulatorDevice) -> String {
        return device.runTime.replacingOccurrences(of: AppConstants.runtimeReplacing, with: "")
    }
    
    /// Sets the current error and updates the `shouldShowError` flag. This method is used to handle errors that occur during the loading of simulators, allowing the UI to react accordingly by showing an alert or error message.
    /// - Parameter error: The `SimulatorError` that occurred, which will be stored in the `currentError` property and trigger the display of an error message in the UI.
    /// - Note: The method also prints the error's localized description to the console for debugging purposes.
    private func setError(_ error: SimulatorError) {
        self.currentError = error
        self.shouldShowError = true
        print("\(error.localizedDescription)")
    }
}
