//
//  UserDefaultsTable.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct UserDefaultsTableView: View {
    @Environment(SearchViewModel.self) var searchViewModel
    @Environment(UserDefaultsViewModel.self) var userDefaultsViewModel
    let table: DBDataTable
    
    var body: some View {
        let rows = userDefaultsViewModel.makeRows(from: table)
        Table(of: UserDefaultsRow.self, selection: userDefaultsViewModel.bindingRowSelection(rows: rows)) {
            TableColumnForEach(UserDefaultColumn.allCases) { column in
                TableColumn(column.rawValue) { row in
                    searchViewModel.highlightMatch(in: userDefaultsViewModel.getText(for: column, from: row))
                }
            }
        } rows: {
            ForEach(rows) { row in
                TableRow(row)
            }
        }
        .overlay {
            if userDefaultsViewModel.isLoadingSheet {
                createModifiedProgressView()
            }
        }
        .sheet(isPresented: Binding.from(userDefaultsViewModel, keyPath: \.showDetailSheet)) {
            if let row = userDefaultsViewModel.selectedRow {
                UserDefaultDetailSheet(value: row.value)
            }
        }
    }
}
