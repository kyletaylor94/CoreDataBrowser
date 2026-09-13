//
//  SimulatorSection.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation
import SwiftUI

struct SimulatorSection: View {
    @Environment(SimulatorViewModel.self) var simulatorViewModel
    @Environment(SearchViewModel.self) var searchVM
    @Environment(DBDataViewModel.self) var dbDataVM
    var body: some View {
        if simulatorViewModel.isLoading {
            ProgressView()
        } else if simulatorViewModel.devices.isEmpty {
            ContentUnavailableView {
                Label(AppConstants.SimulatorStrings.simulatorAccessNeeded, systemImage: AppConstants.SimulatorIcons.lock)
            } description: {
                Text(simulatorViewModel.currentError?.errorDescription ?? AppConstants.SimulatorStrings.unknownError)
            } actions: {
                Button(PathConstants.grantAccess) {
                    Task { await simulatorViewModel.loadSimulators() }
                }
            }
        } else if simulatorViewModel.shouldShowEmptyDeviceView {
            ContentUnavailableView(
                AppConstants.SimulatorStrings.noSimulatorsFound,
                systemImage: AppConstants.SimulatorIcons.iphoneSlash,
                description: Text(AppConstants.SimulatorStrings.noSimulatorsFoundSubtitle)
            )
        } else {
            SimulatorListView()
                .onChange(of: searchVM.searchedText) { _, newValue in
                    searchVM.search(text: newValue, devices: simulatorViewModel.devices, tables: dbDataVM.coreDataTables)
                }
        }
    }
}
