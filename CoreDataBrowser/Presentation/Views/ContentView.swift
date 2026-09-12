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
    @State private var schemaGraphViewModel: SchemaGraphViewModel
    @State private var contentViewModel: ContentViewModel
    
    init(
        simulatorViewModel: SimulatorViewModel,
        dbDataViewModel: DBDataViewModel,
        userDefaultsViewModel: UserDefaultsViewModel,
        searchViewModel: SearchViewModel,
        pathManager: PathManagerImpl,
        schemaGraphViewModel: SchemaGraphViewModel,
        contentViewModel: ContentViewModel
    ) {
        _simulatorViewModel = State(wrappedValue: simulatorViewModel)
        _dbDataViewModel = State(wrappedValue: dbDataViewModel)
        _userDefaultsViewModel = State(wrappedValue: userDefaultsViewModel)
        _searchViewModel = State(wrappedValue: searchViewModel)
        _pathManager = State(wrappedValue: pathManager)
        _schemaGraphViewModel = State(wrappedValue: schemaGraphViewModel)
        _contentViewModel = State(wrappedValue: contentViewModel)
    }
    
    var body: some View {
        NavigationSplitView {
            SimulatorSection()
        } content: {
            DataSourceSection()
                .onChange(of: simulatorViewModel.selectedDevice) { _, _ in
                    Task { await contentViewModel.refreshAllData() }
                }
        } detail: {
            DBDetailSection()
        }
        .onChange(of: dbDataViewModel.coreDataTables) { _, newTables in
            schemaGraphViewModel.updateCoreData(tables: newTables, relationships: dbDataViewModel.coreDataRelationships)
        }
        .onChange(of: dbDataViewModel.swiftDataTables) { _, newTables in
            schemaGraphViewModel.updateSwiftData(tables: newTables, relationships: dbDataViewModel.swiftDataRelationships)
        }
        .onChange(of: dbDataViewModel.selectedTable) { _, newTable in
            schemaGraphViewModel.focusNode(named: newTable?.name)
        }
        .overlay {
            if contentViewModel.isLoadingRefresh {
                ModifiedProgressView()
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
            /// Delay initial loading until the window is visible so that
            /// NSOpenPanel can be presented correctly.
            await contentViewModel.loadInitialData()
        }
        .toolbar {
            CustomToolBarButton(helpText: "Refresh all data", placement: .navigation, icon: "arrow.trianglehead.2.clockwise") {
                Task { await contentViewModel.refreshAllData() }
            }
            
            CustomToolBarButton(helpText: "Toggle schema graph presentation", placement: .primaryAction, icon: "point.3.connected.trianglepath.dotted") {
                schemaGraphViewModel.isSchemaGraphPresented.toggle()
            }
            
            CustomToolBarButton(helpText: "Open settings", placement: .primaryAction, icon: "gearshape") {
                pathManager.isSheetPresented.toggle()
            }
        }
        .sheet(isPresented: .from(pathManager, keyPath: \.isSheetPresented)) {
            AppFolderSheet(pathManager: pathManager)
        }
        .sheet(isPresented: .from(schemaGraphViewModel, keyPath: \.isSchemaGraphPresented)) {
            SchemaGraphView()
                .environment(schemaGraphViewModel)
                .frame(minWidth: 1000, idealWidth: 1300, minHeight: 700, idealHeight: 850)
        }
        .createAlert(
            isPresented: .from(simulatorViewModel, keyPath: \.shouldShowError),
            errorMessage: simulatorViewModel.currentError?.errorDescription,
            onDismiss: { simulatorViewModel.shouldShowError = false }
        )
    }
}
