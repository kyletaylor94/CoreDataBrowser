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
        } else if simulatorViewModel.devices.isEmpty && !simulatorViewModel.isLoading {
            ContentUnavailableView(
                "No Simulators Found",
                systemImage: "iphone.slash",
                description: Text("No simulator devices are available. Please check your Xcode installation or start a simulator.")
            )
        } else {
            SimulatorListView()
                .onChange(of: searchVM.searchedText) { _, newValue in
                    searchVM.search(text: newValue, devices: simulatorViewModel.devices, tables: dbDataVM.coreDataTables)
                }
        }
    }
}
