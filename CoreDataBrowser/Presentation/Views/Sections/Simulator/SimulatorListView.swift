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
                handleDeviceSelection(device)
            } label: {
                SimulatorCellView(device: device, searchVM: searchVM, simulatorViewModel: simulatorViewModel)
            }
        }
        .frame(minWidth: 350, minHeight: 500)
        .task { await simulatorViewModel.loadSimulators() }
        .searchable(text: searchBinding)
        .createAlert(isPresented: errorBinding, errorMessage: simulatorViewModel.currentError?.errorDescription, onDismiss: {
            simulatorViewModel.shouldShowError = false
        })
    }
    private func createSimulatorCell(device: SimulatorDevice) -> some View {
        HStack{
            VStack(alignment: .leading) {
                searchVM.highlightMatch(in: device.name)
                    .font(.headline)
                searchVM.highlightMatch(in: simulatorViewModel.runTimeTextReplacing(device: device))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(device.state)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

extension SimulatorListView {
    private func handleDeviceSelection(_ device: SimulatorDevice) {
        simulatorViewModel.selectedDevice = device
        dbDataVM.loadSimulatorApps(for: device)
    }
    
    private var searchBinding: Binding<String> {
        Binding(
            get: { searchVM.searchedText },
            set: { searchVM.searchedText = $0 }
        )
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { simulatorViewModel.shouldShowError },
            set: { simulatorViewModel.shouldShowError = $0 }
        )
    }
}
