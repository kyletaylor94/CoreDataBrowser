//
//  ContentViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 12..
//

import Foundation
import Observation

@MainActor
@Observable
final class ContentViewModel {
    private let simulatorViewModel: SimulatorViewModel
    private let dbDataViewModel: DBDataViewModel
    private let userDefaultsViewModel: UserDefaultsViewModel
    
    var isLoadingRefresh: Bool = false
    
    init(simulatorViewModel: SimulatorViewModel, dbDataViewModel: DBDataViewModel, userDefaultsViewModel: UserDefaultsViewModel) {
        self.simulatorViewModel = simulatorViewModel
        self.dbDataViewModel = dbDataViewModel
        self.userDefaultsViewModel = userDefaultsViewModel
    }
    
    func loadInitialData() async {
        guard !isLoadingRefresh else { return }
        try? await Task.sleep(for: .milliseconds(300))
        await refreshAllData()
    }
    
    func refreshAllData() async {
        isLoadingRefresh = true
        defer { isLoadingRefresh = false }
        if simulatorViewModel.devices.isEmpty {
            await simulatorViewModel.loadSimulators()
        }
        await loadAllDataSources()
        dbDataViewModel.refreshCurrentTables()
        userDefaultsViewModel.refreshCurrentTables()
    }
    
    private func loadAllDataSources() async {
        guard let device = simulatorViewModel.selectedDevice else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.userDefaultsViewModel.loadUserDefaults(for: device) }
            group.addTask { await self.dbDataViewModel.refresh(selectedDevice: device) }
            group.addTask { await self.dbDataViewModel.loadSwiftData(for: device) }
        }
    }
}
