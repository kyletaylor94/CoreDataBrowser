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
                    title: "Core Data",
                    icon: "cylinder.split.1x2",
                    hasError: dbDataHasError,
                    errorMessage: dbDataViewModel.error?.localizedDescription,
                    onDismiss: { dbDataViewModel.selectedTable = nil },
                    onErrorDismiss: { dbDataViewModel.hasError = false }
                )
            }
            if let swiftDataTable = dbDataViewModel.secondaryTable {
                DetailContentView(
                    table: swiftDataTable,
                    isLoading: dbDataViewModel.isLoadingSwiftData,
                    title: "SwiftData",
                    icon: "externaldrive.badge.checkmark",
                    hasError: dbDataHasError,
                    errorMessage: dbDataViewModel.error?.localizedDescription,
                    onDismiss: { dbDataViewModel.secondaryTable = nil },
                    onErrorDismiss: { dbDataViewModel.hasError = false },
                    isSwiftDataContent: true
                )
            }
            
            if let userDefaultTable = userDefaultsViewModel.selectedUserDefaultTable {
                DetailContentView(
                    table: userDefaultTable,
                    isLoading: userDefaultsViewModel.isLoading,
                    title: "User Defaults",
                    icon: "gearshape.2",
                    hasError: userDefaultsHasError,
                    errorMessage: userDefaultsViewModel.error?.localizedDescription,
                    onDismiss: { userDefaultsViewModel.selectedUserDefaultTable = nil },
                    onErrorDismiss: { userDefaultsViewModel.hasError = false },
                    isUserDefaultsDetail: true
                )
            }
        }
    }
    private var dbDataHasError: Binding<Bool> {
        Binding(
            get: { dbDataViewModel.hasError },
            set: { dbDataViewModel.hasError = $0 }
        )
    }
    
    private var userDefaultsHasError: Binding<Bool> {
        Binding(
            get: { userDefaultsViewModel.hasError },
            set: { userDefaultsViewModel.hasError = $0 }
        )
    }
}
