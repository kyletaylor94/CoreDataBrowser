//
//  UserDefaultsTable.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

enum UserDefaultColumnEnum: String, CaseIterable , Identifiable {
    case key = "Key"
    case value = "Value"
    case type = "Type"
    var id: String { return self.rawValue }
}

struct UserDefaultsTableView: View {
    @Environment(SearchViewModel.self) var searchViewModel
    @Environment(UserDefaultsViewModel.self) var userDefaultsViewModel
    let table: DBDataTable
    
    var body: some View {
        let rows = userDefaultsViewModel.makeRows(from: table)
        Table(of: UserDefaultsRow.self, selection: Binding(
            get: { userDefaultsViewModel.selectedRow.map { Set([$0.id]) } ?? [] },
            set: { newSelection in
                if let firstID = newSelection.first,
                   let row = rows.first(where: { $0.id == firstID }) {
                    userDefaultsViewModel.selectedRow = row
                    userDefaultsViewModel.isLoadingSheet = true
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        userDefaultsViewModel.isLoadingSheet = false
                        userDefaultsViewModel.showDetailSheet = true
                    }
                }
            }
        )) {
            TableColumnForEach(UserDefaultColumnEnum.allCases) { column in
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
        .sheet(isPresented: userDefaultsViewModel.bindingUserDefaultsDetailSheet) {
            if let row = userDefaultsViewModel.selectedRow {
                UserDefaultDetailSheet(value: row.value)
            }
        }
    }
}
