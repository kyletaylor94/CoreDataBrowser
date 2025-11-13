//
//  ContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var selectedDevice: SimulatorDevice? = nil
    @State private var selectedTable: CoreDataTable? = nil
    @State private var selectedUserDefaultTable: UserDefaultsTable? = nil
    @State private var searchedText: String = ""
    var body: some View {
        NavigationSplitView{
            createSimulatorList()
                .onAppear { viewModel.loadSimulators() }
                .searchable(text: $searchedText)
                .onChange(of: searchedText) { _, newValue in
                    searchVM.search(text: newValue, devices: viewModel.devices, tables: viewModel.tables)
                }
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            viewModel
                                .refresh(
                                    selectedDevice: selectedDevice,
                                    selectedTable: selectedTable,
                                    selectedUserDefaultsTable: selectedUserDefaultTable
                                )
                        } label: {
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                        }
                        .help(Text("Refresh the list of simulators"))
                    }
                }
        } content: {
            HStack(spacing: 0) {
                createCoreDataEntities()
                createUserDefaultTables()
            }
        } detail: {
            VStack{
                if let table = selectedTable {
                    createTableContent(table: table)
                }
                
                Divider()
                
                if let table = selectedUserDefaultTable {
                    createUserDefaultTableContent(table: table)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.shouldShowError, presenting: viewModel.currentError) { error in
            Button("OK") { viewModel.shouldShowError = false }
        } message: { error in
            Text(error.errorDescription ?? "Unknown Error")
        }
    }
    private func createSimulatorList() -> some View {
        List(viewModel.devices) { device in
            Button {
                selectedDevice = device
                viewModel.loadSimulatorApps(for: device)
            } label: {
                createSimulatorCell(device: device)
            }
        }
        .frame(minWidth: 350, minHeight: 500)
    }
    
    private func createSimulatorCell(device: SimulatorDevice) -> some View {
        HStack{
            VStack(alignment: .leading) {
                searchVM.highlightMatch(in: device.name, searchText: searchedText)
                    .font(.headline)
                
                searchVM.highlightMatch(in: viewModel.runTimeTextReplacing(device: device), searchText: searchedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(device.state)
                .foregroundStyle(device.state == "Booted" ? .green : .gray)
        }
        .padding(.vertical, 4)
    }
    private func createUserDefaultTableContent(table: UserDefaultsTable) -> some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    ForEach(Array(zip(table.columns, table.types)), id: \.0) { column, type in
                        VStack(alignment: .leading, spacing: 0) {
                            searchVM.highlightMatch(in: type, searchText: searchedText)
                            
                            searchVM.highlightMatch(in: column, searchText: searchedText)
                        }
                        .bold()
                        .padding(.horizontal, 4)
                        .frame(minWidth: 120, alignment: .leading)
                    }
                }
                .padding(.bottom)
                
                // Data rows
                ForEach(table.rows.indices, id: \.self) { rowIndex in
                    let row = table.rows[rowIndex]
                    HStack {
                        ForEach(row.indices, id: \.self) { colIndex in
                            searchVM.highlightMatch(in: row[colIndex], searchText: searchedText)
                                .frame(minWidth: 120, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.horizontal, 4)
                        }
                    }
                    Divider()
                }
            }
            .padding(.vertical, 4)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .userDefaultsTableDidRefresh)) { notification in
            if let updated = notification.object as? UserDefaultsTable {
                self.selectedUserDefaultTable = updated
            }
        }
    }
    private func createTableContent(table: CoreDataTable) -> some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    ForEach(Array(zip(table.columns, table.types)), id: \.0) { column, type in
                        VStack(alignment: .leading, spacing: 0) {
                            searchVM.highlightMatch(in: type, searchText: searchedText)
                            
                            searchVM.highlightMatch(in: column, searchText: searchedText)
                        }
                        .bold()
                        .padding(.horizontal, 4)
                        .frame(minWidth: 120, alignment: .leading)
                    }
                }
                .padding(.bottom)
                
                // Data rows
                ForEach(table.rows.indices, id: \.self) { rowIndex in
                    let row = table.rows[rowIndex]
                    HStack {
                        ForEach(row.indices, id: \.self) { colIndex in
                            searchVM.highlightMatch(in: row[colIndex], searchText: searchedText)
                                .frame(minWidth: 120, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.horizontal, 4)
                        }
                    }
                    Divider()
                }
            }
            .padding(.vertical, 4)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .tableDidRefresh)) { notification in
            if let updated = notification.object as? CoreDataTable {
                self.selectedTable = updated
            }
        }
    }
    
    private func createCoreDataEntities() -> some View {
        List(viewModel.tables) { table in
            Button {
                selectedTable = table
            } label: {
                searchVM.highlightMatch(in: table.name, searchText: searchedText)
            }
        }
    }
    
    private func createUserDefaultTables() -> some View {
        List(viewModel.userDefaultsTable) { table in
            Button(table.name) {
                selectedUserDefaultTable = table
            }
        }
        .onChange(of: selectedDevice) { oldValue, newValue in
            if let device = newValue {
                viewModel.loadUserDefaults(for: device)
            }
        }
    }
}

#Preview {
    ContentView()
}
