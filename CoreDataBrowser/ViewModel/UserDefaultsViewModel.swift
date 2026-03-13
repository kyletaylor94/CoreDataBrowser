//
//  UserDefaultsViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import Observation

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
        //        if let selectedUserDefaultTable,
        //           let updated = userDefaultsTable.first(where: { $0.name == selectedUserDefaultTable.name }) {
        //            NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
        //        }
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
}
