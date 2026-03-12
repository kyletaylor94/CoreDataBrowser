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
final class UserDefaultsViewModel {
    var userDefaultsTable: [DBDataTable] = []
    var selectedUserDefaultTable: DBDataTable? = nil
    
    var isLoading = false
    var hasError = false
    var error: UserDefaultsError? = nil
    
    var showDetailSheet = false
    var selectedRow: UserDefaultsRow?
    var isLoadingSheet: Bool = false
    
    private let repository: UserDefaultsRepository
    
    init(repository: UserDefaultsRepository) {
        self.repository = repository
    }
    
    func refreshUserDefaults() {
        if let selectedUserDefaultTable,
           let updated = userDefaultsTable.first(where: { $0.name == selectedUserDefaultTable.name }) {
            DispatchQueue.main.async { [weak self] in
                self?.userDefaultsTable = self?.userDefaultsTable ?? []
                NotificationCenter.default.post(name: .tableDidRefresh, object: updated)
            }
        }
    }
    
    func loadUserDefaults(for device: SimulatorDevice) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            userDefaultsTable = try await repository.loadUserDefaults(for: device)
        } catch {
            self.error = .cannotLoadApps(device.path)
            self.hasError = true
        }
    }
}
