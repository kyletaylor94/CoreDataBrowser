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
    @State private var userDefaultsViewModel = UserDefaultsViewModel(repository: UserDefaultsRepositoryImpl())
    @State private var searchVM = SearchViewModelFactory.make()
    @State private var pathManager: PathManagerImpl
    
    init() {
        let pm = PathManagerImpl()
        _pathManager = State(wrappedValue: pm)
        _simulatorViewModel = State(wrappedValue: SimulatorViewModel(useCase: SimulatorUseCaseImpl(repository: SimulatorRepositoryImpl(pathManager: pm))))
        _dbDataVM = State(wrappedValue: DBDataViewModel(pathManager: pm))
    }
    
    var body: some View {
        NavigationSplitView {
            SimulatorSection()
                .appEnvironment(simulator: simulatorViewModel, swiftData: dbDataVM, search: searchVM)
        } content: {
            DataSourceSection()
                .appEnvironment(swiftData: dbDataVM, userDefaults: userDefaultsViewModel, search: searchVM)
                .onChange(of: simulatorViewModel.selectedDevice) { _, device in
                    Task { await handleDeviceSelection(device) }
                }
        } detail: {
            DBDetailSection()
                .appEnvironment(swiftData: dbDataVM, userDefaults: userDefaultsViewModel, search: searchVM)
        }
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
            dbDataVM.refresh(selectedDevice: simulatorViewModel.selectedDevice)
            await handleDeviceSelection(simulatorViewModel.selectedDevice)
        }
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
    
    private func handleDeviceSelection(_ device: SimulatorDevice?) async {
        guard let device else { return }
        await userDefaultsViewModel.loadUserDefaults(for: device)
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
    
    var pathManagerBinding: Binding<Bool> {
        Binding(
            get: { pathManager.isSheetPresented },
            set: { pathManager.isSheetPresented = $0 }
        )
    }
}

