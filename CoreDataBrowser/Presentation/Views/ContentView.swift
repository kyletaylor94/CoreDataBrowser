//
//  ContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import SwiftUI

struct ContentView: View {
    @State private var simulatorViewModel: SimulatorViewModel
    @State private var dbDataViewModel: DBDataViewModel
    @State private var userDefaultsViewModel: UserDefaultsViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var pathManager: PathManagerImpl
    @State private var isLoadingRefresh: Bool = false
    init(
        simulatorViewModel: SimulatorViewModel,
        dbDataViewModel: DBDataViewModel,
        userDefaultsViewModel: UserDefaultsViewModel,
        searchViewModel: SearchViewModel,
        pathManager: PathManagerImpl
    ) {
        _simulatorViewModel = State(wrappedValue: simulatorViewModel)
        _dbDataViewModel = State(wrappedValue: dbDataViewModel)
        _userDefaultsViewModel = State(wrappedValue: userDefaultsViewModel)
        _searchViewModel = State(wrappedValue: searchViewModel)
        _pathManager = State(wrappedValue: pathManager)
    }
    
    var body: some View {
        NavigationSplitView {
            SimulatorSection()
        } content: {
            DataSourceSection()
                .onChange(of: simulatorViewModel.selectedDevice) { _, _ in
                    Task { await loadAllDataSources() }
                }
        } detail: {
            DBDetailSection()
        }
        .overlay {
            if isLoadingRefresh {
                createModifiedProgressView()
            }
        }
        .appEnvironment(
            simulatorViewModel: simulatorViewModel,
            dbDataViewModel: dbDataViewModel,
            userDefaultsViewModel: userDefaultsViewModel,
            searchViewModel: searchViewModel
        )
        .navigationSplitViewColumnWidth(min: 340, ideal: 340, max: 340)
        .task {
            if isLoadingRefresh {
                return
            }
            await refreshAllData()
        }
        .toolbar {
            toolBarButton(placement: .navigation, icon: "arrow.trianglehead.2.clockwise") { Task { await refreshAllData() } }
            toolBarButton(placement: .primaryAction, icon: "gearshape") { pathManager.isSheetPresented.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tableDidRefresh)) { notification in
            updateSelectedTables(notification: notification)
        }
        .sheet(isPresented: .from(pathManager, keyPath: \.isSheetPresented)) {
            AppFolderSheet(pathManager: pathManager)
        }
    }
}
private extension ContentView {
    private func refreshAllData() async {
        isLoadingRefresh = true
        defer { isLoadingRefresh = false }
        if simulatorViewModel.devices.isEmpty {
            await simulatorViewModel.loadSimulators()
        }
        await loadAllDataSources()
        await refreshCurrentTables()
    }
    
    
    /// Loads all relevant data sources (UserDefaults, CoreData, SwiftData) concurrently for the currently selected simulator device. This method uses Swift's concurrency features to perform multiple asynchronous loading operations at the same time, improving efficiency and reducing wait times for the user. It ensures that all necessary data is refreshed and up-to-date whenever a new device is selected or when a manual refresh is triggered.
    /// - Note: The method checks if there is a selected device before attempting to load data sources, and it uses `withTaskGroup` to manage concurrent tasks for loading user defaults, CoreData, and SwiftData.
    private func loadAllDataSources() async {
        guard let device = simulatorViewModel.selectedDevice else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.userDefaultsViewModel.loadUserDefaults(for: device) }
            group.addTask { await self.dbDataViewModel.refresh(selectedDevice: device) }
            group.addTask { await self.dbDataViewModel.loadSwiftData(for: device) }
        }
    }
    
    /// Refreshes the currently selected tables in the `DBDataViewModel` and `UserDefaultsViewModel` after data sources have been reloaded. This method checks if there are any selected tables in both view models and updates them with the latest data from their respective lists of tables. It ensures that the UI reflects the most current state of the data after a refresh operation.
    private func refreshCurrentTables() async {
        if let selectedTable = dbDataViewModel.selectedTable {
            if let updated = dbDataViewModel.coreDataTables.first(where: { $0.name == selectedTable.name }) {
                dbDataViewModel.selectedTable = updated
            }
        }
        
        if let secondaryTable = dbDataViewModel.secondaryTable {
            if let updated = dbDataViewModel.swiftDataTables.first(where: { $0.name == secondaryTable.name }) {
                dbDataViewModel.secondaryTable = updated
            }
        }
        
        if let selectedUserDefaultTable = userDefaultsViewModel.selectedUserDefaultTable {
            if let updated = userDefaultsViewModel.userDefaultsTable.first(where: { $0.name == selectedUserDefaultTable.name }) {
                userDefaultsViewModel.selectedUserDefaultTable = updated
            }
        }
    }
    
    /// Updates the selected tables in the `DBDataViewModel` and `UserDefaultsViewModel` when a table is refreshed. This method listens for the `.tableDidRefresh` notification and checks if the updated table matches any of the currently selected tables in both view models. If a match is found, it updates the selected table with the new data, ensuring that the UI reflects the latest changes to the table after a refresh operation.
    private func updateSelectedTables(notification: Notification) {
        if let updated = notification.object as? DBDataTable {
            if dbDataViewModel.selectedTable?.id == updated.id {
                dbDataViewModel.selectedTable = updated
            }
            if dbDataViewModel.secondaryTable?.id == updated.id {
                dbDataViewModel.secondaryTable = updated
            }
            if userDefaultsViewModel.selectedUserDefaultTable?.id == updated.id {
                userDefaultsViewModel.selectedUserDefaultTable = updated
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolBarButton(placement: ToolbarItemPlacement, icon: String, action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button {
                action()
            } label: {
                Image(systemName: icon)
            }
        }
    }
}
