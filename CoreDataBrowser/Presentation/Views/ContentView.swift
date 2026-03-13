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
                .onChange(of: simulatorViewModel.selectedDevice) { _, device in
                    Task { await handleDeviceSelection(device) }
                }
        } detail: {
            DBDetailSection()
        }
        .appEnvironment(simulatorViewModel: simulatorViewModel, dbDataViewModel: dbDataViewModel, userDefaultsViewModel: userDefaultsViewModel, searchViewModel: searchViewModel)
        .navigationSplitViewColumnWidth(min: 340, ideal: 340, max: 340)
        .task { await refreshAllData() }
        .toolbar {
            toolBarButton(placement: .navigation, icon: "arrow.trianglehead.2.clockwise") { Task { await refreshAllData() } }
            toolBarButton(placement: .primaryAction, icon: "gearshape") { pathManager.isSheetPresented.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tableDidRefresh)) { notification in
            updateSelectedTables(notification: notification)
        }
        .sheet(isPresented: pathManagerBinding) {
            AppFolderSheet(pathManager: pathManager)
        }
    }
}

private extension ContentView {
    private func refreshAllData() async {
        if simulatorViewModel.devices.isEmpty {
            await simulatorViewModel.loadSimulators()
            dbDataViewModel.refresh(selectedDevice: simulatorViewModel.selectedDevice)
            await handleDeviceSelection(simulatorViewModel.selectedDevice)
        }
    }
    
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
    
    private func handleDeviceSelection(_ device: SimulatorDevice?) async {
        guard let device else { return }
        await userDefaultsViewModel.loadUserDefaults(for: device)
        dbDataViewModel.loadSwiftData(for: device)
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
    
    var pathManagerBinding: Binding<Bool> {
        Binding(
            get: { pathManager.isSheetPresented },
            set: { pathManager.isSheetPresented = $0 }
        )
    }
}

