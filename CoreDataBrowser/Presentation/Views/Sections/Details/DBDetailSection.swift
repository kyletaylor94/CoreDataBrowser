//
//  DBDetailSection.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation
import SwiftUI

struct DBDetailSection: View {
    @Environment(DBDataViewModel.self) var dbDataViewModel
    @Environment(UserDefaultsViewModel.self) var userDefaultsViewModel
    
    var body: some View {
        Group {
            if let coreDataTable = dbDataViewModel.selectedTable {
                DetailContentView(
                    table: coreDataTable,
                    isLoading: dbDataViewModel.isLoading,
                    type: .coreData,
                    hasError: Binding.from(dbDataViewModel, keyPath: \.hasError),
                    errorMessage: dbDataViewModel.error?.localizedDescription,
                    onDismiss: { dbDataViewModel.selectedTable = nil },
                    onErrorDismiss: { dbDataViewModel.hasError = false },
                    copyAction: { dbDataViewModel.copyPathManager.copyPath(for: coreDataTable, type: .coreData) },
                    isCopied: dbDataViewModel.copyPathManager.copiedType == .coreData
                )
            }
            if let swiftDataTable = dbDataViewModel.secondaryTable {
                DetailContentView(
                    table: swiftDataTable,
                    isLoading: dbDataViewModel.isLoadingSwiftData,
                    type: .swiftData,
                    hasError: Binding.from(dbDataViewModel, keyPath: \.hasError),
                    errorMessage: dbDataViewModel.error?.localizedDescription,
                    onDismiss: { dbDataViewModel.secondaryTable = nil },
                    onErrorDismiss: { dbDataViewModel.hasError = false },
                    copyAction: { dbDataViewModel.copyPathManager.copyPath(for: swiftDataTable, type: .swiftData) },
                    isCopied: dbDataViewModel.copyPathManager.copiedType == .swiftData
                )
            }
            
            if let userDefaultTable = userDefaultsViewModel.selectedUserDefaultTable {
                DetailContentView(
                    table: userDefaultTable,
                    isLoading: userDefaultsViewModel.isLoading,
                    type: .userDefaults,
                    hasError: Binding.from(userDefaultsViewModel, keyPath: \.hasError),
                    errorMessage: userDefaultsViewModel.error?.localizedDescription,
                    onDismiss: { userDefaultsViewModel.selectedUserDefaultTable = nil },
                    onErrorDismiss: { userDefaultsViewModel.hasError = false },
                    copyAction: { userDefaultsViewModel.copyPathManager.copyPath(for: userDefaultTable, type: .userDefaults) },
                    isCopied: userDefaultsViewModel.copyPathManager.copiedType == .userDefaults
                )
            }
        }
    }
}
