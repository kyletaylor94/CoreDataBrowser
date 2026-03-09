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
    @Environment(SearchViewModel.self) var searchVM
    let table: DBDataTable
    var body: some View {
        let rows = makeRows(from: table)
        Table(rows) {
            TableColumnForEach(UserDefaultColumnEnum.allCases) { column in
                TableColumn(column.rawValue) { row in
                    searchVM.highlightMatch(in: getText(for: column, from: row))
                }
            }
        }
    }
    private func getText(for column: UserDefaultColumnEnum, from row: UserDefaultsRow) -> String {
         switch column {
         case .key:
             return row.key
         case .value:
             return row.value
         case .type:
             return row.type
         }
     }
    private func makeRows(from table: DBDataTable) -> [UserDefaultsRow] {
        table.rows.map { row in
            UserDefaultsRow(
                key: row.count > 0 ? row[0] : "",
                value: row.count > 1 ? row[1] : "",
                type: row.count > 2 ? row[2] : ""
            )
        }
    }
}
