//
//  UserDefaultsViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class UserDefaultsViewModel: TableRefreshable {
    var userDefaultsTable: [DBDataTable] = []
    var selectedUserDefaultTable: DBDataTable? = nil
    
    var isLoading = false
    var hasError = false
    var error: UserDefaultsError? = nil
    
    var showDetailSheet = false
    var selectedRow: UserDefaultsRow?
    var isLoadingSheet: Bool = false
    
    private let useCase: UserDefaultsUseCase
    
    init(useCase: UserDefaultsUseCase) {
        self.useCase = useCase
    }
    
    var selectedTable: DBDataTable? {
        selectedUserDefaultTable
    }
    
    var tables: [DBDataTable] {
        get { userDefaultsTable }
        set { userDefaultsTable = newValue }
    }
    
    func refreshUserDefaults() {
        refreshSelectedTable()
    }
    
    /// Loads the user defaults for a given simulator device asynchronously. Sets the `isLoading` flag to true while loading and handles errors by updating the `error` and `hasError` properties.
    /// - Parameter device: The `SimulatorDevice` for which to load the user defaults. The method uses the `useCase` to execute the loading and updates the state accordingly.
    /// - Note: The method uses a `defer` statement to ensure that the `isLoading` flag is set back to false after the loading process, regardless of whether it succeeds or fails.
    func loadUserDefaults(for device: SimulatorDevice) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            userDefaultsTable = try await useCase.execute(for: device)
        } catch {
            self.error = .cannotLoadApps(device.path)
            self.hasError = true
        }
    }
    
    /// Retrieves the text for a given column and row in the user defaults table. This method is used to display the appropriate text in the UI based on the column type (key, value, or type).
    /// - Parameters:
    ///  - column: The `UserDefaultColumn` for which to retrieve the text.
    ///  - row: The `UserDefaultsRow` from which to extract the text based on the specified column.
    ///  - Returns: A `String` representing the text to be displayed for the specified column and row in the user defaults table.
    func getText(for column: UserDefaultColumn, from row: UserDefaultsRow) -> String {
        switch column {
        case .key:
            return row.key
        case .value:
            return row.value
        case .type:
            return row.type
        }
    }
    
    func setLoadingStates() {
        isLoadingSheet = true
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            isLoadingSheet = false
            showDetailSheet = true
        }
    }
    
    /// Transforms the currently selected row into a set of UUIDs for use in the table's selection binding. If there is a selected row, it creates a set containing the row's ID; otherwise, it returns an empty set.
    /// - Returns: A `Set<UUID>` representing the ID of the currently selected row
    /// - Note: This transformation allows the selection to be easily managed in SwiftUI's table selection mechanisms.
    private func transFormSelectedRow() -> Set<UUID> {
        selectedRow.map { Set([$0.id]) } ?? []
    }
    
    /// Handles changes in the selection of rows in the user defaults table. When the selection changes, it updates the `selectedRow` property based on the new selection and sets the loading states for displaying the detail sheet.
    /// - Parameters:
    /// - newSelection: A `Set<UUID>` representing the new selection of rows in the table. This is typically provided by the SwiftUI table's selection binding.
    /// - `rows`: The array of `UserDefaultsRow` that are currently displayed in the table. This is used to find the corresponding `UserDefaultsRow` based on the selected UUID.
    ///  - Note: The method checks if there is a new selection and finds the corresponding `UserDefaultsRow` based on the UUID. If a row is selected, it updates the `selectedRow` property and triggers the loading states for showing the detail sheet.
    private func handleSelectionChange(newSelection: Set<UUID>, rows: [UserDefaultsRow]) {
        if let firstID = newSelection.first,
           let row = rows.first(where: { $0.id == firstID }) {
            selectedRow = row
            setLoadingStates()
        }
    }
    
    /// Creates a binding for the selection of rows in the user defaults table. This allows the UI to react to changes in the selected row and update the `selectedRow` property accordingly.
    /// - Parameter rows: The array of `UserDefaultsRow` that are currently displayed in the table. This is needed to find the corresponding `UserDefaultsRow` when the selection changes.
    /// - Returns: A `Binding<Set<UUID>>` that can be used in the table's selection to keep track of the selected row(s) and update the `selectedRow` property when the selection changes.
    /// - Note: The binding's getter transforms the currently selected row into a set of UUIDs, while the setter updates the `selectedRow` based on the new selection from the UI. This allows for seamless integration with SwiftUI's selection mechanisms in tables.
    func bindingRowSelection(rows: [UserDefaultsRow]) -> Binding<Set<UUID>> {
        Binding(get: { self.transFormSelectedRow() }, set: { newSelection in self.handleSelectionChange(newSelection: newSelection, rows: rows) })
    }
    
    /// Transforms the raw data rows from the `DBDataTable` into an array of `UserDefaultsRow` for easier handling in the UI.
    /// - Parameter table: The `DBDataTable` containing the raw rows of user defaults data.
    /// - Returns: An array of `UserDefaultsRow` where each row contains the key, value, and type of a user default entry.
    func makeRows(from table: DBDataTable) -> [UserDefaultsRow] {
        table.rows.map { row in
            UserDefaultsRow(
                key: row.count > 0 ? row[0] : "",
                value: row.count > 1 ? row[1] : "",
                type: row.count > 2 ? row[2] : ""
            )
        }
    }
}
