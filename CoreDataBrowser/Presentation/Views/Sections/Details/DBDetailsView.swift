//
//  CoreDataTableView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct DBDetailsView: View {
    @Environment(DBDataViewModel.self) var dbDataViewModel
    @Environment(SearchViewModel.self) var searchVM
    let table: DBDataTable
    let isSwiftDataContent: Bool
    
    var body: some View {
        let rows = dbDataViewModel.makeTableRows(from: table)
        Table(of: DBDataRow.self, selection: dbDataViewModel.bindingRowSelection(rows: rows, isSwiftDataContent: isSwiftDataContent)) {
            TableColumnForEach(table.formattedColumns.indices, id: \.self) { index in
                TableColumn(table.formattedColumns[index]) { row in
                    let cellValue = row.values.count > index ? row.values[index] : ""
                    searchVM.highlightMatch(in: cellValue)
                }
            }
        } rows: {
            ForEach(rows) { row in
                TableRow(row)
            }
        }
        .overlay {
            if dbDataViewModel.checkIsSwiftDataContent(isSwiftDataContent: isSwiftDataContent) {
                createModifiedProgressView()
            }
        }
        .sheet(isPresented: Binding.from(dbDataViewModel, keyPath: \.isMoreDetailSheetPresented)) {
            if let row = dbDataViewModel.selectedRow {
                DBMoreDetailSheetView(row: row, columns: table.formattedColumns)
            }
        }
    }
}
