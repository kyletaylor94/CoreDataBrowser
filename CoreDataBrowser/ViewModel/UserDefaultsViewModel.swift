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
    
    var userDefaultsHasError: Binding<Bool> {
        Binding(get: { self.hasError }, set: { self.hasError = $0 })
    }
    
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
    
    var bindingUserDefaultsDetailSheet: Binding<Bool> {
        Binding( get: { self.showDetailSheet }, set: { self.showDetailSheet = $0 } )
    }
    
    func getText(for column: UserDefaultColumnEnum, from row: UserDefaultsRow) -> String {
        switch column {
        case .key:
            return row.key
        case .value:
            return row.value
        case .type:
            return row.type
        }
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
