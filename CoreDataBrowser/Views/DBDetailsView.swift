//
//  CoreDataTableView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct DBDetailsView: View {
    @Environment(SearchViewModel.self) var searchVM
    let table: DBDataTable
    var body: some View {
        let rows = makeTableRows(from: table)
        Table(rows) {
            TableColumnForEach(table.formattedColumns.indices, id: \.self) { index in
                TableColumn(table.formattedColumns[index]) { row in
                    let cellValue = row.values.count > index ? row.values[index] : ""
                    searchVM.highlightMatch(in: cellValue)
                }
            }
        }
    }
    private func makeTableRows(from table: DBDataTable) -> [DBDataRow] {
        table.rows.map { row in
            DBDataRow(values: row)
        }
    }
}
