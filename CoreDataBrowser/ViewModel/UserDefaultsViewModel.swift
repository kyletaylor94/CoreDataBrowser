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
    
    private func transFormSelectedRow() -> Set<UUID> {
        selectedRow.map { Set([$0.id]) } ?? []
    }
    
    private func handleSelectionChange(newSelection: Set<UUID>, rows: [UserDefaultsRow]) {
        if let firstID = newSelection.first,
           let row = rows.first(where: { $0.id == firstID }) {
            selectedRow = row
            setLoadingStates()
        }
    }
    
    func bindingRowSelection(rows: [UserDefaultsRow]) -> Binding<Set<UUID>> {
        Binding(get: { self.transFormSelectedRow() }, set: { newSelection in self.handleSelectionChange(newSelection: newSelection, rows: rows) })
    }
    
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
