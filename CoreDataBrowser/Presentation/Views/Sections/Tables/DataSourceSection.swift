//
//  DataSourceView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 07..
//

import Foundation
import SwiftUI

struct DataSourceSection: View {
    @Environment(SearchViewModel.self) var searchVM
    @Environment(UserDefaultsViewModel.self) var userDefaultsVM
    @Environment(DBDataViewModel.self) var dbDataVM
    var body: some View {
        HStack(spacing: 0) {
            if !dbDataVM.coreDataTables.isEmpty {
                DataSourceListView(title: AppConstants.DataSourceName.coreData, tables: dbDataVM.coreDataTables, selectedTable: dbDataVM.selectedTable) { table in
                    dbDataVM.selectedTable = table
                }
            }
            
            if !dbDataVM.swiftDataTables.isEmpty {
                Divider()
                DataSourceListView(title: AppConstants.DataSourceName.swiftData, tables: dbDataVM.swiftDataTables, selectedTable: dbDataVM.secondaryTable) { table in
                    dbDataVM.secondaryTable = table
                }
            }
            
            if !userDefaultsVM.userDefaultsTable.isEmpty {
                Divider()
                DataSourceListView(title: AppConstants.DataSourceName.userDefaults, tables: userDefaultsVM.userDefaultsTable, selectedTable: userDefaultsVM.selectedUserDefaultTable, showHighlight: false) { table in
                    userDefaultsVM.selectedUserDefaultTable = table
                }
            }
        }
    }
}
