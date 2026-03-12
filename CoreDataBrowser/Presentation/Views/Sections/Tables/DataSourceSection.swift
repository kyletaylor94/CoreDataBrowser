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
            coreDataSection
            swiftDataSection
            userDefaultsSection
        }
    }
    @ViewBuilder
    private var coreDataSection: some View {
        if !dbDataVM.coreDataTables.isEmpty {
            createListView(
                title: "CoreData",
                tables: dbDataVM.coreDataTables,
                selectedTable: dbDataVM.selectedTable,
                showHighlight: true
            ) { table in
                dbDataVM.selectedTable = table
            }
        }
    }
    
    @ViewBuilder
    private var swiftDataSection: some View {
        if !dbDataVM.swiftDataTables.isEmpty {
            Divider()
            createListView(
                title: "SwiftData",
                tables: dbDataVM.swiftDataTables,
                selectedTable: dbDataVM.secondaryTable,
                showHighlight: true
            ) { table in
                dbDataVM.secondaryTable = table
            }
        }
    }
    
    @ViewBuilder
    private var userDefaultsSection: some View {
        if !userDefaultsVM.userDefaultsTable.isEmpty {
            Divider()
            createListView(
                title: "UserDefaults",
                tables: userDefaultsVM.userDefaultsTable,
                selectedTable: userDefaultsVM.selectedUserDefaultTable,
                showHighlight: false
            ) { table in
                userDefaultsVM.selectedUserDefaultTable = table
            }
        }
    }
    
    @ViewBuilder
    private func createListView(title: String, tables: [DBDataTable], selectedTable: DBDataTable?, showHighlight: Bool = true, action: @escaping (DBDataTable) -> Void) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            
            List(tables) { table in
                Button {
                    action(table)
                } label: {
                    TableRowView(table: table, showHighlight: showHighlight, searchVM: searchVM)
                }
            }
        }
    }
}
