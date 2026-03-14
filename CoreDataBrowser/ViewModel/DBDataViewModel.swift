//
//  SwiftDataViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation
import SQLite3
import SwiftUI

@MainActor
@Observable
class DBDataViewModel {
    var selectedTable: DBDataTable? = nil
    var secondaryTable: DBDataTable? = nil
    var swiftDataTables: [DBDataTable] = []
    var coreDataTables: [DBDataTable] = []

    var isLoading = false
    var isLoadingSwiftData = false
    var hasError = false
    var error: DBError? = nil
    
    var selectedRow: DBDataRow?
    var isMoreDetailSheetPresented = false
    var isLoadingCoreDataSheet = false
    var isLoadingSwiftDataSheet = false
    
    private let useCase: DBUseCase
    
    init(useCase: DBUseCase) {
        self.useCase = useCase
    }
    
    var dbDataHasError: Binding<Bool> {
        Binding(get: { self.hasError }, set: { self.hasError = $0 })
    }
    
    var bindingIsMoreDetailsSheet: Binding<Bool> {
        Binding(get: { self.isMoreDetailSheetPresented }, set: { self.isMoreDetailSheetPresented = $0 })
    }
    
    func checkIsSwiftDataContent(isSwiftDataContent: Bool) -> Bool {
        return (isSwiftDataContent && isLoadingSwiftDataSheet) || (!isSwiftDataContent && isLoadingCoreDataSheet)
    }
    
    func refresh(selectedDevice: SimulatorDevice?) {
        isLoading = true
        isLoadingSwiftData = true
        defer {
            isLoading = false
            isLoadingSwiftData = false
        }
        guard let selectedDevice else { return }
        loadSimulatorApps(for: selectedDevice)
        refreshCoreDataTables()
    }
    
    func loadSimulatorApps(for device: SimulatorDevice) {
        isLoading = true
        defer { isLoading = false }
        coreDataTables = useCase.executeCoreData(for: device)
    }
    
    func loadSwiftData(for device: SimulatorDevice) {
        isLoadingSwiftData = true
        defer { isLoadingSwiftData = false }
        swiftDataTables = useCase.executeSwiftData(for: device)
    }
    
    private func refreshCoreDataTables() {
        CoreDataTablesRefreshable(viewModel: self).refreshSelectedTable()
    }
}

protocol TableRefreshable {
    var selectedTable: DBDataTable? { get }
    var tables: [DBDataTable] { get set }
}

extension TableRefreshable {
    func refreshSelectedTable() {
        guard let selectedTable,
              let updated = tables.first(where: { $0.name == selectedTable.name }) else {
            return
        }
        NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
    }
}

private struct CoreDataTablesRefreshable: TableRefreshable {
    let viewModel: DBDataViewModel
    
    var selectedTable: DBDataTable? {
        viewModel.selectedTable
    }
    
    var tables: [DBDataTable] {
        get { viewModel.coreDataTables }
        set { viewModel.coreDataTables = newValue }
    }
}
