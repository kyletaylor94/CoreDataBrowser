//
//  ContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import SwiftUI

struct ContentView: View {
    @State private var simulatorViewModel: SimulatorViewModel
    @State private var dbDataVM: DBDataViewModel
    @State private var userDefaultsViewModel = UserDefaultsViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var pathManager: PathManager
    
    init() {
        let pm = PathManager()
        _pathManager = State(wrappedValue: pm)
        _simulatorViewModel = State(wrappedValue: SimulatorViewModel(pathManager: pm))
        _dbDataVM = State(wrappedValue: DBDataViewModel(pathManager: pm))
    }
    
    var body: some View {
        NavigationSplitView {
            simulatorSection
        } content: {
            DataSourceView()
                .appEnvironment(swiftData: dbDataVM, userDefaults: userDefaultsViewModel, search: searchVM)
                .onChange(of: simulatorViewModel.selectedDevice) { _, device in
                    handleDeviceSelection(device)
                }
        } detail: {
            detailSection
        }
        .task {
            if simulatorViewModel.devices.isEmpty {
                refreshAllData()
            }
        }
        .navigationSplitViewColumnWidth(min: 340, ideal: 340, max: 340)
        .toolbar {
            toolBarButton(placement: .navigation, icon: "arrow.trianglehead.2.clockwise") { refreshAllData() }
            toolBarButton(placement: .primaryAction, icon: "gearshape") { pathManager.isSheetPresented.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tableDidRefresh)) { notification in
            updateSelectedTables(notification: notification)
        }
    }
    @ViewBuilder
    private var simulatorSection: some View {
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
                .appEnvironment(simulator: simulatorViewModel, swiftData: dbDataVM, search: searchVM)
                .onChange(of: searchVM.searchedText) { _, newValue in
                    searchVM.search(text: newValue, devices: simulatorViewModel.devices, tables: dbDataVM.coreDataTables)
                }
                .sheet(isPresented: Binding(
                    get: { pathManager.isSheetPresented },
                    set: { pathManager.isSheetPresented = $0 }
                )) {
                    AppFolderSheet(pathManager: pathManager)
                }
        }
    }
 
    @ViewBuilder
    private var detailSection: some View {
        Group {
            if let coreDataTable = dbDataVM.selectedTable {
                DetailContentView(
                    table: coreDataTable,
                    isLoading: dbDataVM.isLoading,
                    title: "Core Data",
                    icon: "cylinder.split.1x2",
                    hasError: $dbDataVM.hasError,
                    errorMessage: dbDataVM.error?.localizedDescription,
                    onDismiss: { dbDataVM.selectedTable = nil },
                    onErrorDismiss: { dbDataVM.hasError = false }
                )
            }
            if let swiftDataTable = dbDataVM.secondaryTable {
                DetailContentView(
                    table: swiftDataTable,
                    isLoading: dbDataVM.isLoading,
                    title: "SwiftData",
                    icon: "externaldrive.badge.checkmark",
                    hasError: $dbDataVM.hasError,
                    errorMessage: dbDataVM.error?.localizedDescription,
                    onDismiss: { dbDataVM.secondaryTable = nil },
                    onErrorDismiss: { dbDataVM.hasError = false }
                )
            }
            
            if let userDefaultTable = userDefaultsViewModel.selectedUserDefaultTable {
                DetailContentView(
                    table: userDefaultTable,
                    isLoading: userDefaultsViewModel.isLoading,
                    title: "User Defaults",
                    icon: "gearshape.2",
                    hasError: $userDefaultsViewModel.hasError,
                    errorMessage: userDefaultsViewModel.error?.localizedDescription,
                    onDismiss: { userDefaultsViewModel.selectedUserDefaultTable = nil },
                    onErrorDismiss: { userDefaultsViewModel.hasError = false },
                    isUserDefaultsDetail: true
                )
            }
        }
        .appEnvironment(search: searchVM)
    }
}

private extension ContentView {
    private func refreshAllData() {
        simulatorViewModel.loadSimulators()
        dbDataVM.refresh(selectedDevice: simulatorViewModel.selectedDevice)
        handleDeviceSelection(simulatorViewModel.selectedDevice)
    }
    
    private func updateSelectedTables(notification: Notification) {
        if let updated = notification.object as? DBDataTable {
            if dbDataVM.selectedTable?.id == updated.id {
                dbDataVM.selectedTable = updated
            }
            if dbDataVM.secondaryTable?.id == updated.id {
                dbDataVM.secondaryTable = updated
            }
            if userDefaultsViewModel.selectedUserDefaultTable?.id == updated.id {
                userDefaultsViewModel.selectedUserDefaultTable = updated
            }
        }
    }
    
    private func handleDeviceSelection(_ device: SimulatorDevice?) {
        guard let device else { return }
        userDefaultsViewModel.loadUserDefaults(for: device)
        dbDataVM.loadSwiftData(for: device)
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

