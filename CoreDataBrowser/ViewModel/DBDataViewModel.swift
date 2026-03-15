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
    
    /// Checks if the content being displayed is from SwiftData or CoreData and whether the corresponding loading state for the detail sheet is active. This method returns a boolean indicating whether the loading state for the detail sheet matches the type of content being displayed, allowing the UI to show appropriate loading indicators based on the content type.
    /// - Parameter isSwiftDataContent: A `Bool` indicating whether the content being displayed is from SwiftData (`true`) or CoreData (`false`). The method uses this parameter to determine which loading state variable to check and returns `true` if the loading state for the detail sheet matches the content type, or `false` otherwise.
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
        refreshSwiftDataTables()
    }
    

    func loadSimulatorApps(for device: SimulatorDevice) {
        isLoading = true
        defer { isLoading = false }
        
        do {
            coreDataTables = try useCase.executeCoreData(for: device)
            hasError = false
            error = nil
        } catch let dbError as DBError {
            hasError = true
            error = dbError
            coreDataTables = []
        } catch {
            hasError = true
            self.error = .queryFailed("Unknown error: \(error.localizedDescription)")
            coreDataTables = []
        }
    }
    
    func loadSwiftData(for device: SimulatorDevice) {
        isLoadingSwiftData = true
        defer { isLoadingSwiftData = false }
        do {
            swiftDataTables = try useCase.executeSwiftData(for: device)
            hasError = false
            error = nil
        } catch let dbError as DBError {
            hasError = true
            error = dbError
            swiftDataTables = []
        } catch {
            hasError = true
            self.error = .queryFailed("Unknown error: \(error.localizedDescription)")
            swiftDataTables = []
        }
    }
    
    func refreshCoreDataTables() {
        let refreshable = CoreDataTablesRefreshable(viewModel: self)
        refreshable.refreshSelectedTable()
    }
    
    func refreshSwiftDataTables() {
        let refreshable = SwiftDataTablesRefreshable(viewModel: self)
        refreshable.refreshSelectedTable()
    }
    
    /// Creates a binding for the row selection in the table. This method takes an array of `DBDataRow` and a boolean indicating whether the content is from SwiftData, and returns a `Binding<Set<UUID>>` that can be used to manage the selection state of the rows in the UI. The binding's getter transforms the currently selected row into a set of UUIDs, while the setter handles changes in the selection by updating the `selectedRow` property and setting the appropriate loading states for the detail sheet based on the content type.
    func bindingRowSelection(rows: [DBDataRow], isSwiftDataContent: Bool) -> Binding<Set<UUID>> {
        Binding(get: { self.transformSelectedRow() }, set: { newSelection in self.handleRowSelectionChange(newSelection: newSelection, rows: rows, isSwiftDataContent: isSwiftDataContent) })
    }
    
    /// Transforms the rows of a given `DBDataTable` into an array of `DBDataRow` instances. This method takes a `DBDataTable` as input and maps its rows to create corresponding `DBDataRow` objects, which can be used for display in the UI.
    func makeTableRows(from table: DBDataTable) -> [DBDataRow] {
        table.rows.map { row in
            DBDataRow(values: row)
        }
    }
    
    /// Handles changes in the row selection for the table. When a new selection is made, it checks if there is a selected row and updates the `selectedRow` property accordingly. It also sets the loading states for the detail sheet based on whether the content is from SwiftData or CoreData.
    private func handleRowSelectionChange(newSelection: Set<UUID>, rows: [DBDataRow], isSwiftDataContent: Bool) {
        if let firstID = newSelection.first,
           let row = rows.first(where: { $0.id == firstID }) {
            selectedRow = row
            setLoadingStates(isSwiftDataContent: isSwiftDataContent)
        }
    }
    
    /// Transforms the currently selected row into a set of UUIDs for use in the table's selection binding. If there is a selected row, it creates a set containing the row's ID; otherwise, it returns an empty set.
    /// - Returns: A `Set<UUID>` representing the ID of the currently selected row
    private func transformSelectedRow() -> Set<UUID> {
        selectedRow.map { Set([$0.id]) } ?? []
    }
    
    /// Sets the loading states for the detail sheet based on whether the content is from SwiftData or CoreData. This method updates the appropriate loading state variable and simulates a loading delay before presenting the detail sheet.
    /// - Parameter isSwiftDataContent: A `Bool` indicating whether the content is from
    /// SwiftData (`true`) or CoreData (`false`). The method uses this parameter to determine which loading state variable to update and how to manage the presentation of the detail sheet after the simulated loading delay.
    /// - Note: The method uses `Task.sleep` to simulate a loading delay of 100 milliseconds, after which it updates the loading state and presents the detail sheet. This allows for a smoother user experience by providing visual feedback during the loading process.
    private func setLoadingStates(isSwiftDataContent: Bool) {
        if isSwiftDataContent {
            isLoadingSwiftDataSheet = true
        } else {
            isLoadingCoreDataSheet = true
        }
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if isSwiftDataContent {
                isLoadingSwiftDataSheet = false
            } else {
                isLoadingCoreDataSheet = false
            }
            isMoreDetailSheetPresented = true
        }
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

private struct SwiftDataTablesRefreshable: TableRefreshable {
    let viewModel: DBDataViewModel
    
    var selectedTable: DBDataTable? {
        viewModel.secondaryTable
    }
    
    var tables: [DBDataTable] {
        get { viewModel.swiftDataTables }
        set { viewModel.swiftDataTables = newValue }
    }
}
