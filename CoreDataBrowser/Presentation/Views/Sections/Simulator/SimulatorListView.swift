//
//  SimulatorListView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 07..
//

import Foundation
import SwiftUI

struct SimulatorListView: View {
    @Environment(SimulatorViewModel.self) var simulatorViewModel
    @Environment(DBDataViewModel.self) var dbDataVM
    @Environment(SearchViewModel.self) var searchVM
        
    var body: some View {
        List(simulatorViewModel.devices) { device in
            Button {
                simulatorViewModel.selectedDevice = device
                dbDataVM.loadSimulatorApps(for: device)
            } label: {
                SimulatorCellView(device: device, searchVM: searchVM, simulatorViewModel: simulatorViewModel)
            }
        }
        .frame(minWidth: 350, minHeight: 500)
        .task { await simulatorViewModel.loadSimulators() }
        .searchable(text: searchVM.searchBinding)
        .createAlert(isPresented: simulatorViewModel.errorBinding, errorMessage: simulatorViewModel.currentError?.errorDescription, onDismiss: {
            simulatorViewModel.shouldShowError = false
        })
    }
}
